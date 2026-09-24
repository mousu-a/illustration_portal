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
  end
end

module ActionDispatch
  class IntegrationTest
    include LoginSupport::Request
  end
end
