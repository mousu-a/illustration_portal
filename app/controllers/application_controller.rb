class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private

  # TODO: Google OAuth実装Issueで session[:user_id] を使った本実装に差し替える
  def current_user
    @current_user ||= User.find_or_create_dev_user
  end
end
