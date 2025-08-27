class PagesController < ApplicationController
  def home
    render HomePage.new, layout: false
  end
end
