class HtmlController < ApplicationController
  before_filter :load_project
  before_filter :add_project_paths

  def show
    render template: params[:page]
  end

  private

  def load_project
    @project = params[:project]
  end

  def add_project_paths
    prepend_view_path Rails.root.join("app", "assets", @project, "html")
    Rails.application.config.assets.prefix = "/assets/#{@project}"
  end
end
