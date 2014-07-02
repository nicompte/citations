# encoding: utf-8

get '/author/find/:name' do |name|
  content_type :json
  Author.where(name: Regexp.new(name, true)).limit(10).to_json
end

get '/authors' do
  @authors = Author.all.asc(:name)
  slim :authors, :locals=>{:title => "Citations - Auteurs"}
end

get '/author/:id' do |id|
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  @author = Author.find(id)
  @quotes = Quote.where(author: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :author, :locals=>{:title => "Citations - #{@author.name}"}
end
