require "test_helper"

class LinkCardTest < ActiveSupport::TestCase
  StubResponse = Struct.new(:message, :body)

  X_OEMBED_HTML = '<blockquote class="twitter-tweet"><p lang="ja">本文</p><a href="https://x.com/user/status/1">日付</a></blockquote>'.freeze

  test ".fetch_metadata 内部でnewし、#fetch_metadataの結果を返す" do
    expected = { title: "リンクカードタイトル" }
    mock_instance = Minitest::Mock.new
    mock_instance.expect(:fetch_metadata, expected)

    actual = LinkCard.stub(:new, mock_instance) do
      LinkCard.fetch_metadata("https://example.com/article")
    end

    assert_equal expected, actual
    mock_instance.verify
  end

  test ".fetch_metadata 取得した結果をキャッシュに保存する" do
    url = "https://example.com/article"
    expected = { title: "リンクカードタイトル" }
    mock_instance = Minitest::Mock.new
    mock_instance.expect(:fetch_metadata, expected)

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      LinkCard.stub(:new, mock_instance) do
        LinkCard.fetch_metadata(url)
      end

      assert_equal expected, Rails.cache.read("link_card:#{url}")
    end
  end

  test ".fetch_metadata 取得に失敗した場合、結果をキャッシュしない" do
    url = "https://example.com/broken"
    mock_instance = Minitest::Mock.new
    mock_instance.expect(:fetch_metadata, nil)

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      LinkCard.stub(:new, mock_instance) do
        LinkCard.fetch_metadata(url)
      end

      assert_not Rails.cache.exist?("link_card:#{url}")
    end
  end

  test "#fetch_metadata metadataをHashで返す" do
    html = <<~HTML
      <html><head>
        <meta property="og:title" content="リンクカードタイトル">
        <meta property="og:url" content="https://example.com/article">
        <meta property="og:image" content="https://example.com/image.png">
        <link rel="icon" href="https://example.com/favicon.ico">
      </head></html>
    HTML
    stub_response = StubResponse.new("OK", html)
    expected = {
      title: "リンクカードタイトル",
      image_url: "https://example.com/image.png",
      favicon_url: "https://example.com/favicon.ico"
    }

    actual = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://example.com/article").fetch_metadata
    end

    assert_equal expected, actual
  end

  test "#fetch_metadata faviconが相対パスの場合、urlを基準に絶対パスへ解決する" do
    html = <<~HTML
      <html><head>
        <meta property="og:title" content="リンクカードタイトル">
        <meta property="og:url" content="https://example.com/article">
        <meta property="og:image" content="https://example.com/image.png">
        <link rel="shortcut icon" href="/assets/favicon.ico">
      </head></html>
    HTML
    stub_response = StubResponse.new("OK", html)
    expected = "https://example.com/assets/favicon.ico"

    result = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://example.com/article").fetch_metadata
    end

    assert_equal expected, result[:favicon_url]
  end

  test "#fetch_metadata urlが空の場合、nilを返す" do
    assert_nil LinkCard.fetch_metadata(nil)
  end

  test "#fetch_metadata OGPが存在しない場合、nilを返す" do
    html_without_ogp = "<html><head></head></html>"
    stub_response = StubResponse.new("OK", html_without_ogp)

    result = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://example.com/no-ogp").fetch_metadata
    end

    assert_nil result
  end

  test "#fetch_metadata 危険なURLへのリクエストはブロックし、nilを返す" do
    unsafe_url = "http://127.0.0.1/secret"
    result = LinkCard.new(unsafe_url).fetch_metadata

    assert_nil result
  end

  test "#fetch_metadata XのURLの場合、OGPのキーを含まずoEmbedのhtmlだけをHashで返す" do
    stub_response = StubResponse.new("OK", { html: X_OEMBED_HTML }.to_json)

    actual = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://x.com/user/status/1").fetch_metadata
    end

    assert_equal({ html: X_OEMBED_HTML }, actual)
  end

  test "#fetch_metadata XのURLの場合、htmlから危険なタグや属性を取り除く" do
    dangerous_html = <<~HTML
      <blockquote class="twitter-tweet" onclick="steal()">
        <p lang="ja">本文</p>
        <img src="https://example.com/x.png" onerror="steal()">
        <a href="javascript:steal()">リンク</a>
        <script>steal()</script>
      </blockquote>
    HTML
    stub_response = StubResponse.new("OK", { html: dangerous_html }.to_json)

    actual = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://x.com/user/status/1").fetch_metadata
    end

    assert_includes actual[:html], '<blockquote class="twitter-tweet">'
    assert_includes actual[:html], '<p lang="ja">本文</p>'
    dangerous_tags_and_attributes = [ "onclick", "onerror", "javascript:", "<script", "<img" ]
    dangerous_tags_and_attributes.each do |dangerous_tag_or_attribute|
      assert_not_includes actual[:html], dangerous_tag_or_attribute
    end
  end

  test "#fetch_metadata XのURLの末尾に/photo/や/video/が付いている場合、取り除いてfetchする" do
    stub_response = StubResponse.new("OK", { html: X_OEMBED_HTML }.to_json)
    expected_request = Minitest::Mock.new
    expected_request.expect(
      :call, stub_response, [ LinkCard::OEMBED_ENDPOINT ],
      params: { url: "https://x.com/user/status/1", omit_script: true, dnt: true, lang: "ja" },
      http_options: LinkCard::HTTP_OPTIONS
    )
    expected_request.expect(
      :call, stub_response, [ LinkCard::OEMBED_ENDPOINT ],
      params: { url: "https://x.com/user/status/2", omit_script: true, dnt: true, lang: "ja" },
      http_options: LinkCard::HTTP_OPTIONS
    )

    SsrfFilter.stub(:get, expected_request) do
      LinkCard.new("https://x.com/user/status/1/photo/1").fetch_metadata
      LinkCard.new("https://x.com/user/status/2/video/1").fetch_metadata
    end

    assert_mock expected_request
  end

  test "#fetch_metadata Xのドメインでも投稿以外のURLの場合、oEmbedではなくOGPから取得する" do
    html = <<~HTML
      <html><head>
        <meta property="og:title" content="プロフィール">
        <meta property="og:url" content="https://x.com/user">
        <meta property="og:image" content="https://example.com/image.png">
      </head></html>
    HTML
    stub_response = StubResponse.new("OK", html)
    expected_metadata = {
      title: "プロフィール",
      image_url: "https://example.com/image.png",
      favicon_url: nil
    }

    actual = SsrfFilter.stub(:get, stub_response) do
      LinkCard.new("https://x.com/user").fetch_metadata
    end

    assert_equal expected_metadata, actual
  end
end
