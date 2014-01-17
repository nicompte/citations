# encoding: utf-8

require 'sinatra'
require 'slim'
require './model.rb'
require 'json'

Mongoid.load!("config/mongoid.yml", :production)

require 'mongoid'

get '/quote' do
  slim :new_quote
end

post '/quote' do

  author = Author.where(_id: params[:quote]["author"]) || Author.where(name: params[:quote]["author"])
  unless author.exists?
    author = Author.create(:name => params[:quote]["author"])
  else
    author = author.first
  end

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

get '/author/find/:name' do |name|
  content_type :json
  Author.where(name: Regexp.new(name, true)).limit(10).to_json
end

get '/book/find/author/:author/book/:book' do |author, book|
  content_type :json
  Book.where(author: author, name: Regexp.new(book, true)).limit(10).to_json
end

get '/authors' do
  @authors = Author.all
  slim :authors
end

get '/author/:id' do |id|
  @author = Author.find(id)
  slim :author
end

get '/book/:id' do |id|
  @book = Book.find(id)
  slim :book
end

get '/*/?' do
  @quotes = Quote.all.limit(10)
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end