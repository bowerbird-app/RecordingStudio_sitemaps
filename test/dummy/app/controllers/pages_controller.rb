class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    @page = @parent_recordable if defined?(@parent_recordable)
    @page ||= Page.find_by(id: params[:id])
    head :not_found unless @page
  end
end
