require 'rack-cache'
require 'sinatra'
require 'faraday'
require 'RMagick'
require 'librato-rack'

def skin_url(username)
  "http://s3.amazonaws.com/MinecraftSkins/#{username}.png"
end

configure do
  STDOUT.sync = true
  set :ttl, 24 * 60 * 60
end

# Preload default avatar
configure do
  response = Faraday.get(skin_url('char'))
  skin = Magick::ImageList.new
  skin.from_blob(response.body)

  helm = skin.crop(40, 8, 8, 8)
  head = skin.crop(8, 8, 8, 8)

  avatar = head.composite(helm, 0, 0, Magick::AtopCompositeOp)

  set :default_avatar, avatar
end

use Librato::Rack

use Rack::Cache, verbose: true,
                 default_ttl: settings.ttl,
                 allow_revalidate: true,
                 allow_reload: true

get '/helm/:username/:size.png' do |username, size|
  response = Librato.measure('mojang.skin.request.time') do
    Faraday.get(skin_url(username))
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
      settings.default_avatar
    end.sample(size.to_i, size.to_i)
  end

  headers 'Etag' => response.headers['ETag']
  content_type :png
  avatar.to_blob
end
