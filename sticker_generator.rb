#! /usr/bin/env ruby

require 'json'
require 'chunky_png'

TOKEN = "yixrvxlr7rduxadiix7ra7aydtaltlri"
FILE_UPLOAD_URL = "https://fs.go.to/filesharing/upload"

def sticker_url_for_text(words)
  if words.length == 1
    words = words[0].split(' ')
  end
  person = words[0]
  rest_text = words[1..-1].join(" ")
  whole_text = words.join(" ")

  url = custom_url(person, rest_text)
  url ||= random_sticker_url_with_key rest_text
  url ||= random_sticker_url_with_key whole_text
end

def custom_url(person_name, text)
  info = parsed_custom_sticker_info
  if user_exists? person_name
    unless info[text].nil?
      file_path = create_custom_sticker(info[text][:image], person_name, info[text][:x], info[text][:y])
      url = upload file_path
    end
  end
  url
end

def parsed_custom_sticker_info
  custom_stickers_file = File.new("./custom-sticker-support/custom_stickers.info")
  info = {}
  while line = custom_stickers_file.gets
    line = line.chomp
    tokens = line.split(":")
    info[tokens[0]] = {:image => tokens[1], :x => tokens[2], :y => tokens[3]}
  end
  custom_stickers_file.close
  info
end

def user_exists?(user)
  user_faces = File.new("./custom-sticker-support/user_faces.info")
  while line = user_faces.gets
    line = line.chomp
    if line.eql? user
      user_faces.close
      return true
    end
  end
  user_faces.close
  return false
end

def create_custom_sticker(sticker_name, user_name, position_x, position_y)
  sticker = ChunkyPNG::Image.from_file("./custom-sticker-support/custom-stickers/#{sticker_name}.png")
  user  = ChunkyPNG::Image.from_file("./custom-sticker-support/user-faces/#{user_name}.png")
  sticker.compose!(user, Integer(position_x), Integer(position_y))
  
  path = "/tmp/custom_sticker#{rand(10000)}.png"
  sticker.save(path, :fast_rgba) 
  path
end

def upload(file_path)
  uuid = rand(100000)
  response = `curl -v --form file=@"#{file_path}" "#{FILE_UPLOAD_URL}?token=#{TOKEN}&uuid=#{uuid}"`
  response_data = JSON.parse response
  response_data["longUrl"]
end

def random_sticker_url_with_key(key)
  meta_data = File.read('./custom-sticker-support/stickers.json')
  stickers_data = JSON.parse meta_data
  stickers_info = parsed_info_from_meta_data stickers_data
  sticker_set = stickers_info[key]  
  url = sticker_set[rand(sticker_set.length)] unless sticker_set.nil?
  url
end

def parsed_info_from_meta_data(meta_data)
  collections = meta_data["collections"]
  sets = collections[0]["sets"]

  results = {}
  sets.each do |set|
    sticker_set_name = set["id"]
    set["items"].each do |item|
      sticker_name = encode item["name"]
      sticker_source = item["source"]
      update_results(results, sticker_name, sticker_source)
    end
  end
  results
end

def encode(string)
  string.downcase.gsub("(", "").gsub(")", "").gsub("'", "").gsub("?", "")
end

def update_results(results, key, value)
  if results[key].nil?
    results[key] = []
  end
  results[key].push value
end

def main
  url = sticker_url_for_text ARGV
  print url.chomp unless url.nil?
end

main if __FILE__ == $0
