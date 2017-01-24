require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'dotenv'
Dotenv.load

payload = {:uid => ENV['FIREBASE_UID'], :auth_data => ENV['FIREBASE_EMAIL'], :other_auth_data => ENV['FIREBASE_PASS']}
generator = Firebase::FirebaseTokenGenerator.new(ENV['FIREBASE_KEY'])
token = generator.create_token(payload)

firebase = Firebase::Client.new(ENV['FIREBASE_URL'], token)

a = Mechanize.new
a.cookie_jar.load 'cookies'

login_url = 'http://www.takproject.net/forums/index.php?login'
a.get(login_url) do |page|

  if (heading = page.search('h3:contains("Server Status")').first)
    puts 'Already logged in'
  else
    puts 'Not logged in'
    # Submit the login form
    my_page = page.form_with(:action => 'index.php?login/login') do |f|
      f.login    = ENV['TAKP_LOGIN']
      f.password = ENV['TAKP_PASSWORD']
    end.click_button

    a.cookie_jar.save_as 'cookies', :session => true, :format => :yaml
    heading = my_page.search('h3:contains("Server Status")').first
  end

  count = heading.parent.search('.secondaryContent span').last.text.to_i

  data = {
    created: Firebase::ServerValue::TIMESTAMP,
    count: count
  }

  response = firebase.push("takp_online", data)
end
