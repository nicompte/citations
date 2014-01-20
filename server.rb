# encoding: utf-8

require 'sinatra'
require 'slim'
require './model.rb'
require 'json'
require 'newrelic_rpm'

Mongoid.load!("config/mongoid.yml", :production)

require 'mongoid'

enable :sessions

post '/login' do
  content_type :json
  if params[:user] == 'nico' && params[:password] == 'nico'
    session[:user] = "nico"
    return {:login => "ok"}.to_json
  else
    status 401
    return {:login => "ko"}.to_json
  end
end

get '/logout' do
  session[:user] = nil
  redirect "/"
end

get '/quote' do
  redirect '/' if session[:user].nil?
  slim :new_quote
end

post '/quote' do
  redirect '/' if session[:user].nil?

  author = Author.where(_id: params[:quote]["author"]).exists? ? Author.find(params[:quote]["author"])
    : Author.find_or_create_by(name: params[:quote]["author"])

  #author = Author.where(_id: params[:quote]["author"]) || Author.where(name: params[:quote]["author"])
  #unless author.exists?
  #  author = Author.create(:name => params[:quote]["author"])
  #else
  #  author = author.first
  #end

  book = Book.where(_id: params[:quote]["book"]) || Book.where(author: author, name: params[:quote]["book"])
  unless book.exists?
    book = Book.create(:name => params[:quote]["book"], author: author)
  else
    book = book.first
  end

  quote = Quote.create(
    :text => params[:quote]["text"],
    book: book
  )
  #quote.book = book

  #book.quotes.push(quote)
  author.quotes.push(quote)

  redirect "/"
end

delete '/quote/:id' do |id|
  content_type :json
  Quote.find(id).delete
  return {:delete => "ok"}.to_json
end

get '/author/find/:name' do |name|
  content_type :json
  Author.where(name: Regexp.new(name, true)).limit(10).to_json
end

get '/book/find/author/:author/book/:book' do |author, book|
  content_type :json
  Book.where(author: author, name: Regexp.new(book, true)).limit(10).to_json
end

get '/authors' do
  @authors = Author.all.asc(:name)
  slim :authors
end

get '/books' do
  @books = Book.all.asc(:name)
  slim :books
end

get '/author/:id' do |id|
  @author = Author.find(id)
  slim :author
end

get '/book/:id' do |id|
  @book = Book.find(id)
  @quotes = Quote.where(book: @book)
  slim :book
end

get '/about' do
  slim :about
end

get '/ping' do
  'ok'
end

get '/*/?' do
  @quotes = Quote.all.desc(:_id).limit(10)
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end