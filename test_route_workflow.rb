#!/usr/bin/env ruby
# Test script to verify route creation workflow

require 'net/http'
require 'uri'
require 'json'

puts "Testing Route Creation Workflow"
puts "=" * 50

# Test data
base_url = "http://localhost:3000"
username = "testworkflow"
password = "password123"

puts "\n1. Creating test user and road trip..."
system("docker compose exec web rails runner '
  user = User.find_or_create_by(username: \"#{username}\") do |u|
    u.password = \"#{password}\"
  end
  road_trip = user.road_trips.find_or_create_by(name: \"Test Workflow Trip\")
  puts \"User ID: #{user.id}\"
  puts \"Road Trip ID: #{road_trip.id}\"
'")

puts "\n2. Testing the workflow:"
puts "   - Login at: #{base_url}/login"
puts "   - Username: #{username}"
puts "   - Password: #{password}"
puts "\n3. Navigate to road trip and click 'Add Route'"
puts "   - This should now take you to a dedicated form page (not a modal)"
puts "\n4. Fill in the route details and click 'Preview Route on Map'"
puts "   - You'll be redirected to a confirmation page"
puts "\n5. Select a date/time and click 'Add Route to Trip'"
puts "   - The route will be saved and you'll return to the road trip page"

puts "\n" + "=" * 50
puts "Workflow setup complete! You can now test manually."
