class UsersController < ApplicationController
  before_action :require_login

  def destroy
    current_user.destroy!
    session.delete(:user_id)
    redirect_to root_path, notice: "退会しました。", status: :see_other
  end
end
