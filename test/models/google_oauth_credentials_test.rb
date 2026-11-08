require "test_helper"

class GoogleOauthCredentialsTest < ActiveSupport::TestCase
  test "#missing_keys 両方設定されている場合は空を返す" do
    env = { "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret" }

    assert_empty GoogleOauthCredentials.new(env).missing_keys
  end

  test "#missing_keys 空文字は未設定として扱う" do
    env = { "GOOGLE_CLIENT_ID" => "", "GOOGLE_CLIENT_SECRET" => "secret" }

    assert_equal [ "GOOGLE_CLIENT_ID" ], GoogleOauthCredentials.new(env).missing_keys
  end

  test "#validate! 両方設定されている場合は例外を出さない" do
    env = { "GOOGLE_CLIENT_ID" => "id", "GOOGLE_CLIENT_SECRET" => "secret" }

    assert_nothing_raised { GoogleOauthCredentials.new(env).validate! }
  end

  test "#validate! GOOGLE_CLIENT_IDが未設定の場合はキー名を含む例外を出す" do
    env = { "GOOGLE_CLIENT_SECRET" => "secret" }

    error = assert_raises(GoogleOauthCredentials::MissingError) do
      GoogleOauthCredentials.new(env).validate!
    end

    assert_includes error.message, "GOOGLE_CLIENT_ID"
    assert_not_includes error.message, "GOOGLE_CLIENT_SECRET"
  end

  test "#validate! GOOGLE_CLIENT_SECRETが未設定の場合はキー名を含む例外を出す" do
    env = { "GOOGLE_CLIENT_ID" => "id" }

    error = assert_raises(GoogleOauthCredentials::MissingError) do
      GoogleOauthCredentials.new(env).validate!
    end

    assert_includes error.message, "GOOGLE_CLIENT_SECRET"
    assert_not_includes error.message, "GOOGLE_CLIENT_ID"
  end

  test "#validate! 両方未設定の場合は両方のキー名を含む例外を出す" do
    error = assert_raises(GoogleOauthCredentials::MissingError) do
      GoogleOauthCredentials.new({}).validate!
    end

    assert_includes error.message, "GOOGLE_CLIENT_ID"
    assert_includes error.message, "GOOGLE_CLIENT_SECRET"
  end
end
