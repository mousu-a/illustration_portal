require "ssrf_filter"
require "open_graph_reader"
require "nokogiri"

class LinkCard
  HTTP_OPTIONS = { open_timeout: 3, read_timeout: 5 }.freeze

  CACHE_EXPIRES_IN = 7.days

  OEMBED_ENDPOINT = "https://publish.x.com/oembed".freeze
  X_HOSTS = %w[x.com www.x.com twitter.com www.twitter.com mobile.twitter.com].freeze
  X_POST_PATH = %r{\A/\w+/status/\d+}
  X_MEDIA_SUFFIX = %r{/(photo|video)/\d+\z}

  def self.fetch_metadata(url)
    return nil if url.blank?

    Rails.cache.fetch("link_card:#{url}", expires_in: CACHE_EXPIRES_IN, skip_nil: true) do
      new(url).fetch_metadata
    end
  end

  def initialize(url)
    @url = url
  end

  def fetch_metadata
    x_post? ? fetch_x_post : fetch_ogp
  end

  private

  def x_post?
    uri = URI.parse(@url)
    # Xでは、ユーザーのプロフィールなど、post以外のURLをoEmbedに渡すとリンクカードに必要なHTMLが返ってこない
    # そのためpostのURLのみoEmbedの対象とする
    X_HOSTS.include?(uri.host) && uri.path.match?(X_POST_PATH)
  rescue URI::InvalidURIError
    false
  end

  def fetch_x_post
    response = SsrfFilter.get(
      OEMBED_ENDPOINT,
      params: { url: @url.sub(X_MEDIA_SUFFIX, ""), omit_script: true, dnt: true, lang: "ja" },
      http_options: HTTP_OPTIONS
    )
    return nil unless response.message == "OK"

    allowed_tags = %w[blockquote p a br]
    allowed_attributes = %w[class href lang dir]
    sanitized_html = ActionController::Base.helpers.sanitize(
      JSON.parse(response.body)["html"],
      tags: allowed_tags,
      attributes: allowed_attributes
    )
    { html: sanitized_html }
  rescue StandardError => e
    Rails.logger.error "LinkCard#fetch_x_post failed: #{e.message}"
    nil
  end

  def fetch_ogp
    response = SsrfFilter.get(@url, http_options: HTTP_OPTIONS)
    return nil unless response.message == "OK"

    object = OpenGraphReader.parse!(response.body, @url)
    {
      title: object.og.title,
      image_url: object.og.image&.url,
      favicon_url: favicon(response.body)
    }
  rescue StandardError => e
    Rails.logger.error "LinkCard#fetch_ogp failed: #{e.message}"
    nil
  end

  def favicon(html)
    doc = Nokogiri::HTML(html)
    favicon_path = doc.at_css('link[rel="icon"], link[rel="shortcut icon"]')&.attr("href")
    return unless favicon_path

    absolute_regexp = URI::DEFAULT_PARSER.make_regexp

    # faviconはサイトによって絶対パス、相対パスと異なるため、どちらにも対応できる実装にしている
    if absolute_regexp.match?(favicon_path)
      favicon_path
    else
      URI.join(@url, favicon_path).to_s
    end
  end
end
