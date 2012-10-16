class HtmlController < ApplicationController
  before_filter :load_project, only: :show
  before_filter :add_project_paths, only: :show

  layout :layout_param, only: :show

  def index
  end
  
  def show
    render template: params[:page]
  end

  private

  def load_project
    @project = params[:project]
  end

  def add_project_paths
    prepend_view_path Rails.root.join("..", @project, "Repo", "html")
    Rails.application.config.assets.prefix = "/assets/#{@project}"
  end
  
  def layout_param
    params[:layout] || "application"
  end
end
