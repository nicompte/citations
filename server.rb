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
  slim :quote, :locals=>{:title => "Citations - #{@quote.author.name}, #{@quote.book.name}"}
end

get '/quote/rand' do
  count = Quote.or( {hidden: false}, {hidden: true, user: session[:user]} ).count
  return count
end

post '/quote' do
  redirect '/' if session[:user].nil?

  author = Author.where(_id: params[:quote]["author"]).exists? ? Author.find(params[:quote]["author"])
    : Author.find_or_create_by(name: params[:quote]["author"])

  book = Book.where(_id: params[:quote]["book"]).exists? ? Book.find(params[:quote]["book"])
    : Book.create(:name => params[:quote]["book"], author: author)

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
  if session[:user] != quote.user
    status 401
    return {:delete => "ko"}.to_json
  end
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
  if session[:user] != quote.user
    status 401
    return {:edit => "ko"}.to_json
  end
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
  slim :authors, :locals=>{:title => "Citations - Auteurs"}
end

get '/books' do
  @books = Book.all.asc(:name)
  slim :books, :locals=>{:title => "Citations - Livres"}
end

get '/author/:id' do |id|
  @author = Author.find(id)
  @quotes = Quote.where(author: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)
  slim :author, :locals=>{:title => "Citations - #{@author.name}"}
end

get '/book/:id' do |id|
  @book = Book.find(id)
  @quotes = Quote.where(book: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)
  slim :book, :locals=>{:title => "Citations - #{@book.author.name}, #{@book.name}"}
end

get '/search' do
  q = params[:q]
  @authors = Author.where(name: Regexp.new(q, true)).asc(:name)
  @books = Book.where(name: Regexp.new(q, true)).asc(:name)
  @quotes = Quote.where(text: Regexp.new(q, true)).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)
  @query = q
  slim :search
end

get '/user/:id' do |id|
  @user = User.find(id)
  @quotes = Quote.where(user: @user).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id)

  @elems = @quotes.inject({authors: [], books:[]}) do |elems, quote|
    #unless authors.any? {|author| quote.author._id == author._id}
    unless elems[:authors].include? quote.author
      elems[:authors].push(quote.author)
    end
    unless elems[:books].include? quote.book
      elems[:books].push(quote.book)
    end
    elems
  end

  @elems[:authors].sort_by! { |a| a["name"] }
  @elems[:books].sort_by! { |b| b["name"] }

  slim :"user/index"
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
    @quotes = Quote.all.desc(:_id)
  end
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end