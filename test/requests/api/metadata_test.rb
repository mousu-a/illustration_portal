require "test_helper"

class API::MetadataTest < ActionDispatch::IntegrationTest
  test "GET /api/metadata リクエストが成功するとmetadataを返す" do
    expected = {
      title: "リンクカードタイトル",
      image_url: "https://example.com/image.png",
      favicon_url: "https://example.com/favicon.ico"
    }

    LinkCard.stub(:fetch_metadata, expected) do
      get api_metadata_path, params: { url: "https://example.com/article" }
    end

    assert_response :success
    assert_equal expected.stringify_keys, response.parsed_body
  end

  test "GET /api/metadata リクエストが失敗すると422エラー" do
    nonexistent_url = "https://example.aabbcc/broken"
    LinkCard.stub(:fetch_metadata, nil) do
      get api_metadata_path, params: { url: nonexistent_url }
    end

    assert_response :unprocessable_content
    assert_equal "Failed to fetch metadata", response.parsed_body["error"]
  end
end
