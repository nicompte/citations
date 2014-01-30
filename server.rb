# encoding: utf-8

require 'sinatra'

#use Rack::Static,
#  :urls => ["/images", "/scripts", "/css"],
#  :root => "public"

use Rack::Deflater

require 'slim'
require './model.rb'
require 'json'
require 'newrelic_rpm'
require 'securerandom'
require 'digest'

configure :development do
  require "better_errors"
  require "binding_of_caller"
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

Mongoid.load!("config/mongoid.yml", :production)

require 'mongoid'

require 'kaminari/sinatra'
require 'padrino-helpers'
require 'mail'

Mail.defaults do
  delivery_method :smtp, {
    :address   => "smtp.sendgrid.net",
    :port      => 587,
    :domain    => "barbotte.net",
    :user_name => ENV['SENDGRID_USERNAME'],
    :password  => ENV['SENDGRID_PASSWORD'],
    :authentication => 'plain',
    :enable_starttls_auto => true
  }
end

register Kaminari::Helpers::SinatraHelpers

enable :sessions

post '/login' do
  content_type :json
  user = User.where(name: params[:user])
  if user.exists? && user.first.password == Digest::MD5.hexdigest(params[:password])
    if user.first.validated == false
      return {:login => "ko", :message => "Veuillez valider votre email."}.to_json
    end
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

post '/register' do

  alreadyExisting = User.or( {name: params[:user]["name"]}, {email: params[:user]["email"]} )
  redirect '/' unless alreadyExisting.nil? or !alreadyExisting.exists?

  params[:user]["validated"] = false
  params[:user]["token"] = SecureRandom.hex(15)
  params[:user]["password"] = Digest::MD5.hexdigest params[:user]["password"]
  user = User.create(params[:user])
  url = "http://citations.barbotte.net/user/#{user._id}/token/#{params[:user]['token']}"

  mail = Mail.new

  mail.to = params[:user]["email"]
  mail.from = 'no-reply@barbotte.net'
  mail.subject = "Validation de l'email citations.barbotte.net"
  mail.content_type = 'text/html; charset=UTF-8'
  mail.body = Slim::Template.new('./views/register-mail.slim').render([{:url => url, :name => params[:user]["name"]}])

  mail.deliver!

  redirect '/'
end

get '/user/:id/token/:token' do |user, token|
  user = User.find(user)
  if user.token == token
    user.validated = true
    user.save
  end
  redirect '/'
end

get '/admin/*' do
  if session[:user].nil? || session[:user][:role] != "admin"
    redirect '/'
  end
  pass
end

get '/admin/users' do
  @users = User.all.asc(:name)
  slim :users
end

post '/admin/author/edit' do
  author = Author.find params[:id]
  author.name = params[:name]
  author.save
  redirect '/authors'
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

  params[:quote]["book"] = "Hors livre" if params[:quote]["book"].nil? || params[:quote]["book"] == ""

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
  @quotes = Quote.where(author: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :author, :locals=>{:title => "Citations - #{@author.name}"}
end

get '/book/:id' do |id|
  @book = Book.find(id)
  @quotes = Quote.where(book: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :book, :locals=>{:title => "Citations - #{@book.author.name}, #{@book.name}"}
end

get '/search' do
  q = params[:q]
  @authors = Author.where(name: Regexp.new(q, true)).asc(:name)
  @books = Book.where(name: Regexp.new(q, true)).asc(:name)
  @quotes = Quote.where(text: Regexp.new(q, true)).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  @query = q
  slim :search
end

get '/user/:id' do |id|
  @user = User.find(id)
  @quotes = Quote.where(user: @user).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])

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
  @quotes = Quote.or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :index
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end
