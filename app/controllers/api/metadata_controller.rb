class API::MetadataController < ApplicationController
  def index
    metadata = LinkCard.fetch_metadata(params[:url])

    if metadata
      render json: metadata
    else
      render json: { error: "Failed to fetch metadata" }, status: :unprocessable_content
    end
  end
end
