# encoding: utf-8

require 'sinatra'
require 'slim'
require './model.rb'
require 'mongoid'

#Mongoid.load!("config/mongoid.yml", :production)

get '/quote' do
  slim :new_quote
end

post '/quote' do
  Quote.create(
    params[:quote]
  )
end

get '/*/?' do
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end