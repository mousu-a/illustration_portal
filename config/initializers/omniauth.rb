Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"], { prompt: "select_account" }
  on_failure { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
end

Rails.application.config.after_initialize do
  # テストとDockerビルド(assets:precompile)は秘密情報なしで起動するため、検証しない
  next if Rails.env.test? || ENV["SECRET_KEY_BASE_DUMMY"].present?

  GoogleOauthCredentials.new.validate!
rescue GoogleOauthCredentials::MissingError => e
  # 本番は未設定のまま起動させない
  raise if Rails.env.production?

  # 開発では、ログイン以外の作業を止めないよう警告にとどめる
  warn e.message
end
