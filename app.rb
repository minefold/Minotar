require 'rack-cache'
require 'sinatra'
require 'faraday'
require 'RMagick'
require 'librato-rack'

one_day = 24 * 60 * 60

use Librato::Rack

use Rack::Cache, verbose: true,
                 default_ttl: one_day,
                 allow_revalidate: true,
                 allow_reload: true

get '/helm/:username/:size.png' do |username, size|
  url = "http://s3.amazonaws.com/MinecraftSkins/#{username}.png"
  response = Librato.measure('mojang.skin.request.time') do
    Faraday.get(url)
  end

  avatar = Librato.measure('mojang.skin.composite.time') do
    if response.status == 200
      Librato.increment 'mojang.skin.custom'

      skin = Magick::ImageList.new
      skin.from_blob(response.body)

      helm = skin.crop(40, 8, 8, 8)
      head = skin.crop(8, 8, 8, 8)

      head.composite(helm, 0, 0, Magick::AtopCompositeOp)
    else
      Librato.increment 'mojang.skin.default'

      url = "http://s3.amazonaws.com/MinecraftSkins/char.png"
      response = Faraday.get(url)

      skin = Magick::ImageList.new
      skin.from_blob(response.body)

      helm = skin.crop(40, 8, 8, 8)
      head = skin.crop(8, 8, 8, 8)

      head.composite(helm, 0, 0, Magick::AtopCompositeOp)
    end.sample(size.to_i, size.to_i)
  end

  headers 'Etag' => response.headers['ETag']
  content_type :png
  avatar.to_blob
end
