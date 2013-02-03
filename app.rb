require 'rack-cache'
require 'sinatra'
require 'faraday'
require 'RMagick'

one_day = 24 * 60 * 60

use Rack::Cache, verbose: true,
                 default_ttl: one_day,
                 allow_revalidate: true,
                 allow_reload: true

get '/helm/:username/:size.png' do |username, size|
  url = "http://s3.amazonaws.com/MinecraftSkins/#{username}.png"
  response = Faraday.get(url)

  if response.status == 200
    skin = Magick::ImageList.new
    skin.from_blob(response.body)

    helm = skin.crop(40, 8, 8, 8)
    head = skin.crop(8, 8, 8, 8)

    avatar = head.composite(helm, 0, 0, Magick::AtopCompositeOp)
  else
    url = "http://s3.amazonaws.com/MinecraftSkins/char.png"
    response = Faraday.get(url)

    skin = Magick::ImageList.new
    skin.from_blob(response.body)

    helm = skin.crop(40, 8, 8, 8)
    head = skin.crop(8, 8, 8, 8)

    avatar = head.composite(helm, 0, 0, Magick::AtopCompositeOp)
  end

  headers 'Etag' => response.headers['ETag']
  content_type :png
  avatar.sample(size.to_i, size.to_i).to_blob
end
