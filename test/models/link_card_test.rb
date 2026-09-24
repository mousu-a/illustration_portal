require "test_helper"

class LinkCardTest < ActiveSupport::TestCase
  StubResponse = Struct.new(:message, :body)

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
end
