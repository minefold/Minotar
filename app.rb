require 'sinatra'
require 'faraday'
require 'RMagick'

get '/' do
  redirect 'https://minotar.net'
end

get '/helm/:username/:size.png' do |username, size|
  url = "http://s3.amazonaws.com/MinecraftSkins/#{username}.png"
  response = Faraday.get(url)

  if response.status == 200
    skin = Magick::ImageList.new
    skin.from_blob(response.body)

    helm = skin.crop(40, 8, 8, 8)
    head = skin.crop(8, 8, 8, 8)

    avatar = head.composite(helm, 0, 0, Magick::AtopCompositeOp)

    content_type :png
    avatar.sample(size.to_i, size.to_i).to_blob
  else
    status 404
    'not found'
  end
end
