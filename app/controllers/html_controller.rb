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
    assets_dir = Rails.root.join('..', @project, 'Repo')
    prepend_view_path File.join(assets_dir, 'html')
    Rails.application.config.assets.prefix = "/assets/#{@project}"
    Compass.configuration.sprite_load_path      =  File.join(assets_dir, 'images')
    Compass.configuration.generated_images_path =  File.join(Rails.public_path, 'assets', @project)
  end

  def layout_param
    params[:layout] || "application"
  end
end
