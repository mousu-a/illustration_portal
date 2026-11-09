module RateLimitSupport
  def create_rate_limit_key(user)
    "rate-limit:reference_archives:#{user.id}"
  end

  # rate_limit と同じ increment で書き込み、500回のリクエストを送らずに上限状態を作る
  def use_up_create_limit(user, count: ReferenceArchivesController::MONTHLY_CREATE_LIMIT)
    Rails.cache.increment(create_rate_limit_key(user), count, expires_in: 1.month)
  end
end
