class PagesController < ApplicationController
  def home
    render HomePage.new(current_user: current_user), layout: false
  end

  def about
    render AboutPage.new(current_user: current_user), layout: false
  end
end
