class PagesController < ApplicationController
  def home
    render HomePage.new(current_user: current_user), layout: false
  end
end
