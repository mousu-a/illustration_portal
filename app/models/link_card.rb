require "ssrf_filter"
require "open_graph_reader"
require "nokogiri"

class LinkCard
  HTTP_OPTIONS = { open_timeout: 3, read_timeout: 5 }.freeze

  def self.fetch_metadata(url)
    new(url).fetch_metadata
  end

  def initialize(url)
    @url = url
  end

  def fetch_metadata
    response = SsrfFilter.get(@url, http_options: HTTP_OPTIONS)
    return nil unless response.message == "OK"

    object = OpenGraphReader.parse!(response.body, @url)
    {
      title: object.og.title,
      image_url: object.og.image&.url,
      favicon_url: favicon(response.body)
    }
  rescue StandardError => e
    Rails.logger.error "LinkCard#fetch_metadata failed: #{e.message}"
    nil
  end

  private

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
