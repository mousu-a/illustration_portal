ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

Rails.root.glob("test/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    include OmniAuthSupport
    include RateLimitSupport

    # レート制限のカウンタがテスト間で残らないように消す
    setup do
      Rails.cache.clear
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include LoginSupport::Request
  end
end
