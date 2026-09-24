require "test_helper"

class OmniAuthUserResolverTest < ActiveSupport::TestCase
  test ".find_or_create_user 内部でnewし、#find_or_create_userの結果を返す" do
    expected_user = users(:yamada)
    mock_instance = Minitest::Mock.new
    mock_instance.expect(:find_or_create_user, expected_user)

    actual = OmniAuthUserResolver.stub(:new, mock_instance) do
      OmniAuthUserResolver.find_or_create_user(auth_hash_for(uid: expected_user.uid, provider: expected_user.provider))
    end

    assert_equal expected_user, actual
    mock_instance.verify
  end

  test "#find_or_create_user 登録済みユーザーの場合作成せずにfindして返す" do
    user = users(:yamada)
    auth_hash = auth_hash_for(uid: user.uid, provider: user.provider, email: user.email)

    found_user = assert_no_difference("User.count") do
      OmniAuthUserResolver.new(auth_hash).find_or_create_user
    end

    assert_equal user, found_user
  end

  test "#find_or_create_user 未登録ユーザーの場合作成して返す" do
    auth_hash = auth_hash_for(uid: "New1234", provider: "google_oauth2")

    created_user = assert_difference("User.count", 1) do
      OmniAuthUserResolver.new(auth_hash).find_or_create_user
    end

    assert created_user.persisted?
  end

  test "#find_or_create_user メールアドレスがない場合ユーザーを作成しない" do
    auth_hash = auth_hash_for(uid: "New1234", provider: "google_oauth2", email: nil)

    invalid_user = assert_no_difference("User.count") do
      OmniAuthUserResolver.new(auth_hash).find_or_create_user
    end

    assert_not invalid_user.persisted?
  end
end
