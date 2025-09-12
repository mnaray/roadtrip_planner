require 'rails_helper'

RSpec.describe "About Page Navigation", type: :system do
  def sign_in(user)
    visit login_path
    within "form" do
      fill_in "Username", with: user.username
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end
  end

  describe "navigation bar About link" do
    context "when user is not logged in" do
      it "displays About link in navigation" do
        visit root_path

        expect(page).to have_link("About", href: about_path)
      end

      it "About link navigates to About page" do
        visit root_path
        click_link "About"

        expect(page).to have_current_path(about_path)
        expect(page).to have_content("About Roadtrip Planner")
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it "displays About link in navigation" do
        expect(page).to have_link("About", href: about_path)
      end

      it "About link navigates to About page" do
        click_link "About"

        expect(page).to have_current_path(about_path)
        expect(page).to have_content("About Roadtrip Planner")
      end
    end
  end

  describe "homepage About link" do
    context "when user is not logged in" do
      it "displays About link on homepage" do
        visit root_path

        expect(page).to have_link("About This App", href: about_path)
      end

      it "About link navigates to About page" do
        visit root_path
        click_link "About This App"

        expect(page).to have_current_path(about_path)
        expect(page).to have_content("About Roadtrip Planner")
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        visit root_path
      end

      it "displays About link on homepage" do
        expect(page).to have_link("About This App", href: about_path)
      end

      it "About link navigates to About page" do
        click_link "About This App"

        expect(page).to have_current_path(about_path)
        expect(page).to have_content("About Roadtrip Planner")
      end
    end
  end

  describe "About page content" do
    context "when user is not logged in" do
      before do
        visit about_path
      end

      it "displays main content sections" do
        expect(page).to have_content("About Roadtrip Planner")
        expect(page).to have_content("What is Roadtrip Planner?")
        expect(page).to have_content("Main Features")
        expect(page).to have_content("Getting Started")
      end

      it "displays features list" do
        expect(page).to have_content("Create and manage multiple road trips")
        expect(page).to have_content("Share road trips with friends and family")
        expect(page).to have_content("Plan detailed routes with waypoints and destinations together")
        expect(page).to have_content("Create and manage shared packing lists with your travel companions")
      end

      it "displays action buttons for anonymous users" do
        expect(page).to have_link("Get Started", href: register_path)
        expect(page).to have_link("Sign In", href: login_path)
      end

      it "Get Started button navigates to registration" do
        click_link "Get Started"

        expect(page).to have_current_path(register_path)
      end

      it "Sign In button navigates to login" do
        click_link "Sign In"

        expect(page).to have_current_path(login_path)
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        sign_in(user)
        visit about_path
      end

      it "displays main content sections" do
        expect(page).to have_content("About Roadtrip Planner")
        expect(page).to have_content("What is Roadtrip Planner?")
        expect(page).to have_content("Main Features")
        expect(page).to have_content("Getting Started")
      end

      it "displays personalized getting started content" do
        expect(page).to have_content("You're already signed in")
        expect(page).to have_content("My Road Trips")
      end

      it "displays View My Road Trips button" do
        expect(page).to have_link("View My Road Trips", href: road_trips_path)
      end

      it "View My Road Trips button navigates to road trips index" do
        click_link "View My Road Trips"

        expect(page).to have_current_path(road_trips_path)
      end

      it "does not display registration/login buttons" do
        expect(page).not_to have_link("Get Started", href: register_path)
        expect(page).not_to have_link("Sign In", href: login_path)
      end
    end
  end
end
