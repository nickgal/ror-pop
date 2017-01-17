require 'rubygems'
require 'bundler'
Bundler.require(:default)

require 'dotenv'
Dotenv.load

require 'open-uri'

payload = {:uid => ENV['FIREBASE_UID'], :auth_data => ENV['FIREBASE_EMAIL'], :other_auth_data => ENV['FIREBASE_PASS']}
generator = Firebase::FirebaseTokenGenerator.new(ENV['FIREBASE_KEY'])
token = generator.create_token(payload)

firebase = Firebase::Client.new(ENV['FIREBASE_URL'], token)

doc = Nokogiri::HTML(open(ENV['POP_URL']))

doc.css('.realm-info').each do |realm|
  tier = 1
  data = {
    created: Firebase::ServerValue::TIMESTAMP
  }
  data[:server_name] = realm.css('.server-name').text.strip
  if (player_count_match = realm.css('.player-count').text.match(/(\d+)\/\d+/))
    data[:player_count] = player_count_match.captures.first.to_i
  end


  realm.css('.faction_bar img').each do |tier_img|
    next if tier > 4

    src = tier_img.attr(:src)
    if (order_percent_match = src.match(/order=(\d+)/))
      data["tier_#{tier}_order_count"] = order_percent_match.captures.first.to_i
    end

    if (destro_percent_match = src.match(/destro=(\d+)/))
      data["tier_#{tier}_destruction_count"] = destro_percent_match.captures.first.to_i
    end


    tier += 1
  end
  response = firebase.push("whos_online", data)
end
