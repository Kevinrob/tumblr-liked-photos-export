require 'bundler/setup'

require 'tumblr_client'
require 'httparty'
require 'byebug'
require 'parallel'
require 'date'
require 'ruby-progressbar'
require 'nokogiri'
require 'dotenv/load'

puts "Starting at #{Time.now}"

# Authenticate via OAuth
client = Tumblr::Client.new(
  consumer_key: ENV['TUMBLR_CONSUMER_KEY'],
  consumer_secret: ENV['TUMBLR_CONSUMER_SECRET'],
  oauth_token: ENV['TUMBLR_OAUTH_TOKEN'],
  oauth_token_secret: ENV['TUMBLR_OAUTH_TOKEN_SECRET']
)

def download_photo(uri, like_timestamp, image_dir)
  file_name = "#{image_dir}/#{like_timestamp}_#{File.basename(uri)}"

  return if File.file?(file_name)

  File.open(file_name, 'wb') do |f|
    f.write HTTParty.get(uri).parsed_response
  end
rescue StandardError => e
  puts ":( #{e}"
end

def get_html_src(html)
  doc = Nokogiri::HTML(html)
  doc.css('img').map { |i| i['src'] }
end

image_dir = '\\\\nasrob\Privé\Tumblr\images'
offset = 0

loop do
  puts "Get from #{offset}..."
  api_response = client.likes offset: offset, limit: 1000
  likes = api_response['liked_posts']
  puts "Get #{likes.count} likes..."
  break if likes.empty?

  Parallel.each(likes, progress: 'Download...') do |like|
    like_timestamp = like['liked_timestamp']

    photos = like['photos'] || []
    photos.each do |photo|
      download_photo(photo['original_size']['url'], like_timestamp, image_dir)
    end

    html_photos = get_html_src(like['body'])
    html_photos.compact.each do |photo|
      download_photo(photo, like_timestamp, image_dir)
    end
  end

  offset += likes.count
end
