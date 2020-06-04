require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'byebug'
end

require 'digest/md5'

hash = {}

image_dir = '/mnt/Tumblr/images'

files = Dir.entries(image_dir)
files.each do |file|
  file_name = "#{image_dir}/#{file}"
  next if File.directory?(file_name)

  key = Digest::MD5.hexdigest(IO.read(file_name)).to_sym
  if hash.key?(key)
    hash[key].push(file)
  else
    hash[key] = [file]
  end
end

hash.each_value do |a|
  next if a.length == 1

  puts '=== Identical Files ==='
  a.each do |file|
    is_timestamp = file.split('_')[0].to_i > 0
    puts "\t#{file}" + (is_timestamp ? ' OK' : '')
  end

  if a.any? { |file| file.split('_')[0].to_i > 0 }
    to_keep = a.find { |file| file.split('_')[0].to_i }
    to_delete = a.find { |file| file != to_keep }
    puts "delete #{to_delete}"
    File.delete("#{image_dir}/#{to_delete}") unless to_delete.nil?
  else
    puts "delete #{a[1]}"
    File.delete("#{image_dir}/#{a[1]}") unless a[1].nil?
  end
end
