require 'rails_helper'

RSpec.describe "About Page", type: :system do
  def sign_in(user)
    visit login_path
    within "form" do
      fill_in "Username", with: user.username
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end
  end

  describe "About page accessibility and navigation" do
    context "when user is not logged in" do
      it "can access about page from home page navigation" do
        visit root_path
        click_link "About"

        expect(page).to have_current_path(about_path)
        expect(page).to have_title("About - Roadtrip Planner")
      end

      it "displays navigation with appropriate links for logged out users" do
        visit about_path

        within "nav" do
          expect(page).to have_link("Roadtrip Planner", href: root_path)
          expect(page).to have_link("About", href: about_path)
          expect(page).to have_link("Login", href: login_path)
          expect(page).to have_link("Sign Up", href: register_path)
          expect(page).not_to have_content("Welcome,")
          expect(page).not_to have_button("Logout")
        end
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it "can access about page from any page navigation" do
        visit road_trips_path
        click_link "About"

        expect(page).to have_current_path(about_path)
        expect(page).to have_title("About - Roadtrip Planner")
      end

      it "displays navigation with appropriate links for logged in users" do
        visit about_path

        within "nav" do
          expect(page).to have_link("Roadtrip Planner", href: root_path)
          expect(page).to have_link("About", href: about_path)
          expect(page).to have_link("My Road Trips", href: road_trips_path)
          expect(page).to have_content("Welcome, #{user.username}!")
          expect(page).to have_button("Logout")
          expect(page).not_to have_link("Login")
          expect(page).not_to have_link("Sign Up")
        end
      end
    end
  end

  describe "Markdown content rendering" do
    before do
      visit about_path
    end

    it "renders main heading correctly" do
      expect(page).to have_selector("h1", text: "About Roadtrip Planner")
    end

    it "renders section headings correctly" do
      expect(page).to have_selector("h2", text: "What We Do")
      expect(page).to have_selector("h2", text: "Key Features")
      expect(page).to have_selector("h2", text: "Why Choose Roadtrip Planner?")
      expect(page).to have_selector("h2", text: "Perfect For")
      expect(page).to have_selector("h2", text: "Getting Started")
      expect(page).to have_selector("h2", text: "Tips for Amazing Road Trips")
    end

    it "renders subsection headings correctly" do
      expect(page).to have_selector("h3", text: "Smart Trip Planning")
      expect(page).to have_selector("h3", text: "Comprehensive Organization")
      expect(page).to have_selector("h3", text: "Export & Share")
      expect(page).to have_selector("h3", text: "User-Friendly Experience")
      expect(page).to have_selector("h3", text: "Swiss Quality")
    end

    it "renders bold text correctly" do
      expect(page).to have_selector("strong", text: "Roadtrip Planner")
      expect(page).to have_selector("strong", text: "Interactive Route Planning")
      expect(page).to have_selector("strong", text: "Custom Waypoints")
    end

    it "renders lists correctly" do
      # Check for unordered lists
      expect(page).to have_selector("ul")
      expect(page).to have_selector("li")

      # Check for specific list items
      expect(page).to have_selector("li", text: /Weekend Warriors/)
      expect(page).to have_selector("li", text: /Long-Distance Explorers/)
      expect(page).to have_selector("li", text: /Family Vacations/)
    end

    it "renders emojis correctly" do
      expect(page).to have_content("🚗")
      expect(page).to have_content("✨")
      expect(page).to have_content("🌍")
      expect(page).to have_content("🎯")
      expect(page).to have_content("🚀")
      expect(page).to have_content("💡")
    end

    it "applies proper styling with prose classes" do
      expect(page).to have_selector("article.prose.prose-lg.prose-blue")
    end

    it "displays key feature descriptions" do
      expect(page).to have_content("Design your perfect route with easy-to-use mapping tools")
      expect(page).to have_content("Keep all your road trips organized in one place")
      expect(page).to have_content("Download your routes for use with GPS devices")
    end

    it "displays selling points and benefits" do
      expect(page).to have_content("Our intuitive interface makes trip planning enjoyable")
      expect(page).to have_content("Every traveler is different")
      expect(page).to have_content("Swiss attention to detail and precision")
    end
  end

  describe "Content completeness" do
    before do
      visit about_path
    end

    it "includes all major sections" do
      # Main sections that should be present
      expect(page).to have_content("What We Do")
      expect(page).to have_content("Key Features")
      expect(page).to have_content("Why Choose Roadtrip Planner")
      expect(page).to have_content("Perfect For")
      expect(page).to have_content("Getting Started")
      expect(page).to have_content("Tips for Amazing Road Trips")
    end

    it "includes practical getting started information" do
      expect(page).to have_content("Create Your Trip")
      expect(page).to have_content("Plan Your Route")
      expect(page).to have_content("Organize Details")
      expect(page).to have_content("Export & Go")
    end

    it "includes helpful tips" do
      expect(page).to have_content("Plan Flexibly")
      expect(page).to have_content("Research Local Gems")
      expect(page).to have_content("Pack Smart")
      expect(page).to have_content("Stay Safe")
      expect(page).to have_content("Document Everything")
    end
  end

  describe "Responsive design and layout" do
    before do
      visit about_path
    end

    it "has proper container structure" do
      expect(page).to have_selector("div.max-w-4xl.mx-auto.px-4")
    end

    it "has proper article structure for content" do
      expect(page).to have_selector("article.prose")
    end
  end

  describe "Page metadata and SEO" do
    before do
      visit about_path
    end

    it "has proper page title" do
      expect(page).to have_title("About - Roadtrip Planner")
    end

    it "includes brand mention in content" do
      expect(page).to have_content("Roadtrip Planner")
    end
  end
end
