class GoogleOauthCredentials
  class MissingError < StandardError; end

  REQUIRED_KEYS = %w[GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET].freeze

  def initialize(env = ENV)
    @env = env
  end

  def missing_keys
    REQUIRED_KEYS.select { |key| @env[key].blank? }
  end

  def validate!
    return if missing_keys.empty?

    raise MissingError,
          "Googleログインに必要な環境変数が未設定です: #{missing_keys.join(", ")}。" \
          "本番は .kamal/secrets と GitHub Secrets、開発は .env を確認してください。"
  end
end
