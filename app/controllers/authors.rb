# encoding: utf-8

get '/author/find/:name' do |name|
  content_type :json
  Author.where(name: Regexp.new(name, true)).limit(10).to_json
end

get '/authors' do
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  authors = Author.all.asc(:name)
  @authors = Hash.new
  ('A'..'Z').each do |letter|
    @authors[letter] = authors.select{|author| author.name.starts_with?(letter)}
  end
  slim :authors, :locals=>{:title => "Citations - Auteurs"}, :layout => 'layout'
end

get '/author/:id' do |id|
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  @author = Author.find(id)
  @quotes = Quote.where(author: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :author, :locals=>{:title => "Citations - #{@author.name}"}, :layout => 'layout'
end
