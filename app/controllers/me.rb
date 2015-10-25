# encoding: utf-8

get '/me/*' do
  if session[:user].nil?
    redirect '/'
  end
  pass
end

get '/me/quotes' do
  @quotes = Quote.where( user: session[:user] ).desc(:_id).page(params[:page])
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  slim :index, :locals=>{:title => "Citations - Mes citations", :h1 => "Mes citations"}, :layout => 'layout'
end

get '/me/authors' do
  auth_id = Quote.where(user: session[:user]).distinct(:author)
  @authors = Author.find(auth_id).sort_by! { |a| a["name"] }
  slim :authors, :locals=>{:title => "Citations - Mes auteurs", :h1 => "Mes auteurs"}, :layout => 'layout'
end

get '/me/books' do
  book_id = Quote.where(user: session[:user]).distinct(:book)
  @books = Book.find(book_id).sort_by! { |a| a["name"] }
  slim :books, :locals=>{:title => "Citations - Mes livres", :h1 => "Mes livres"}, :layout => 'layout'
end

get '/me/starred' do
  @quotes = Quote.in(_id: session[:user].starred).desc(:_id).page(params[:page])
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  slim :index, :locals=>{:title => "Citations - Mes citations favorites", :h1 => "Mes citations favorites"}, :layout => 'layout'
end
