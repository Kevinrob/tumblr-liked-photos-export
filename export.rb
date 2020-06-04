require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'tumblr_client'
  gem 'httparty'
  gem 'byebug'
  gem 'parallel'
  gem 'date'
  gem 'ruby-progressbar'
  gem 'nokogiri'
end

# Authenticate via OAuth
client = Tumblr::Client.new(
  consumer_key: '...',
  consumer_secret: '...',
  oauth_token: '...',
  oauth_token_secret: '...'
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

image_dir = '/mnt/Tumblr/images'
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
