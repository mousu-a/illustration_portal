class HomeController < ApplicationController
  def welcome
    redirect_to reference_archives_path if current_user
  end

  def terms
  end

  def privacy
  end
end
