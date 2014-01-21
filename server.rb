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
  user = User.where(name: params[:user])
  if user.exists? && user.first.password == params[:password]
    session[:user] = user.first
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

get '/quote/:id' do |id|
  @quote = Quote.find(id)
  redirect '/' if @quote.hidden && session[:user] != @quote.user
  slim :quote
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
    :hidden => !params[:quote]["hidden"].nil?,
    book: book,
    user: session[:user]
  )

  session[:user].quotes.push(quote)
  author.quotes.push(quote)

  redirect "/"
end

delete '/quote/:id' do |id|
  content_type :json
  quote = Quote.find(id)
  redirect '/' if @quote.hidden && session[:user] != @quote.user
  book = quote.book
  author = quote.author
  quote.delete
  if Quote.where(book: book).length == 0
    book.delete
  end
  if Quote.where(author: author).length == 0
    author.delete
  end

  return {:delete => "ok"}.to_json
end

put '/quote/:id' do |id|
  content_type :json
  quote = Quote.find(id)
  redirect '/' if @quote.hidden && session[:user] != @quote.user
  quote[:text] = params[:quote]["text"]
  quote[:hidden] = !params[:quote]["hidden"].nil?
  quote.save
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
  @quotes = Quote.where(author: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)
  slim :author
end

get '/book/:id' do |id|
  @book = Book.find(id)
  @quotes = Quote.where(book: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)
  slim :book
end

get '/about' do
  slim :about
end

get '/ping' do
  'ok'
end

get '/*/?' do
  if session[:user].nil?
    @quotes = Quote.where(hidden: false).desc(:_id).limit(20)
  else
    @quotes = Quote.all.desc(:_id).limit(20)
  end
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end