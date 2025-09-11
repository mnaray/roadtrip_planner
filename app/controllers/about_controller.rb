class AboutController < ApplicationController
  def index
    render AboutPage.new(current_user: current_user), layout: false
  end
end
