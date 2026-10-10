class API::MetadataController < ApplicationController
  before_action :require_login

  def index
    metadata = LinkCard.fetch_metadata(params[:url])

    if metadata
      render json: metadata
    else
      render json: { error: "Failed to fetch metadata" }, status: :unprocessable_content
    end
  end
end
