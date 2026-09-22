ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # ApplicationController#current_user と同じ固定devユーザーを返す
    # TODO: ユーザー認証を実装したら削除する
    def dev_user
      @dev_user ||= User.find_or_create_dev_user
    end
  end
end
