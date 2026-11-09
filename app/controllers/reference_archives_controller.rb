class ReferenceArchivesController < ApplicationController
  MONTHLY_CREATE_LIMIT = 500

  before_action :require_login
  # 登録の回数だけを数える。削除で件数を戻しても、登録のたびに数えるので回避できない
  rate_limit to: MONTHLY_CREATE_LIMIT, within: 1.month, by: -> { current_user.id },
    with: :render_rate_limited, only: :create
  before_action :set_reference_archive, only: [ :update, :destroy ]

  def index
    reset_create_form_reference_archive
    set_resources
  end

  def create
    @create_reference_archive = current_user.reference_archives.new(reference_archive_params)

    respond_to do |format|
      if @create_reference_archive.save
        reset_create_form_reference_archive
        format.turbo_stream do
          set_resources
          flash.now[:notice] = @create_reference_archive.create_message(@selected_tags)
        end
        format.html { redirect_to reference_archives_path(tags: params[:tags]), notice: "保存しました" }
      else
        @create_form_reference_archive = @create_reference_archive
        set_resources
        format.turbo_stream { render status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @reference_archive.update(reference_archive_params)
        format.turbo_stream do
          set_resources
          flash.now[:notice] = "更新しました"
        end
        format.html { redirect_to reference_archives_path(tags: params[:tags]), notice: "更新しました" }
      else
        set_resources
        reset_create_form_reference_archive
        format.turbo_stream { render status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @reference_archive.destroy
    respond_to do |format|
      format.turbo_stream do
        set_resources
        flash.now[:notice] = "削除しました"
      end
      format.html { redirect_to reference_archives_path, notice: "削除しました", status: :see_other }
    end
  end

  private

  def render_rate_limited
    respond_to do |format|
      format.turbo_stream { render :rate_limited, status: :too_many_requests }
      format.html do
        redirect_to reference_archives_path, alert: t("reference_archives.rate_limited.title"), status: :see_other
      end
    end
  end

  def set_reference_archive
    @reference_archive = current_user.reference_archives.find(params[:id])
  end

  def reset_create_form_reference_archive
    @create_form_reference_archive = ReferenceArchive.new
  end

  def set_resources
    set_reference_archives
    set_tags
  end

  def set_reference_archives
    @selected_tags = Array(params[:tags])
    @reference_archives = current_user.reference_archives
      .includes(:tags)
      .filtered_by_tags(@selected_tags)
      .order(created_at: :desc)
      .page(params[:page])
  end

  def set_tags
    @tags = current_user.reference_archives.tag_counts_on(:tags)
  end

  def reference_archive_params
    params.require(:reference_archive).permit(:url, tag_list: [])
  end
end
