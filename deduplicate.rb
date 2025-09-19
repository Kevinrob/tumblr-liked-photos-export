require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'byebug'
end

require 'digest/md5'
require 'pstore'

store = PStore.new('cache.pstore')
store.transaction do
  store[:by_file] ||= {}
  store[:by_md5] ||= {}
end

image_dir = '\\\\nasrob\Kevin\Tumblr\images'

puts "=== #{image_dir} ==="
puts '=== Compile md5 ==='

files = Dir.entries(image_dir)
files.each do |file|
  store.transaction do
    file_name = "#{image_dir}/#{file}"
    next if File.directory?(file_name)

    if store[:by_file].key?(file_name)
      key = store[:by_file][file_name]
    else
      key = Digest::SHA1.hexdigest(IO.read(file_name))
    end

    puts "#{file_name} => #{key}"
    store[:by_file][file_name] = key

    if store[:by_md5].key?(key)
      store[:by_md5][key] = (store[:by_md5][key] + [file]).uniq
    else
      store[:by_md5][key] = [file]
    end
  end
end

puts '=== Delete ==='
identical_count = 0
store.transaction do
  store[:by_md5].each do |key, a|
    next if a.length == 1

    identical_count += 1

    puts '=== Identical Files ==='
    a.each do |file|
      is_timestamp = file.split('_')[0].to_i > 0
      puts "\t#{file}" + (is_timestamp ? ' OK' : '')
    end

    if a.any? { |file| file.split('_')[0].to_i > 0 }
      to_keep = a.find { |file| file.split('_')[0].to_i }
      to_delete = a.find { |file| file != to_keep }
      puts "delete #{to_delete}"

      if to_delete != nil && File.exist?("#{image_dir}/#{to_delete}")
        File.delete("#{image_dir}/#{to_delete}")
      end
      store[:by_md5][key] = (store[:by_md5][key] - [to_delete])
    else
      puts "delete #{a[1]}"

      if a[1] != nil && File.exist?("#{image_dir}/#{a[1]}")
        File.delete("#{image_dir}/#{a[1]}") unless a[1].nil?
      end
      store[:by_md5][key] = (store[:by_md5][key] - [a[1]])
    end
  end
end

puts "=== Identical files: #{identical_count} ==="
puts '=== Done ==='
