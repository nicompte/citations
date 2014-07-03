# encoding: utf-8

uri = URI.parse(ENV["REDISTOGO_URL"])
store = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

get '/quote' do
  redirect '/' if session[:user].nil?
  slim :new_quote
end

def getDailyQuote(type)

  uri = URI.parse(ENV["REDISTOGO_URL"])
  store = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

  # TODO : Random
  lastQuote = Date.strptime(store.get("daily_date"), "%Y, %m, %d")
  if lastQuote.past? then
    quotes = Quote.all
    quote = nil
    loop do
      quote = quotes.sample
      sameAuthor = quote.author.name == store.get("daily_author")
      break if !sameAuthor && (quote.hidden == false && quote.text.length <= 400)
    end
    store.set("daily_id", quote._id)
    store.set("daily_text", quote.text)
    store.set("daily_author", quote.author.name)
    store.set("daily_book", quote.book.name)
    store.set("daily_date", Time.new.strftime("%Y, %m, %d"))
  end

  if type == "json" then
    return {:text => store.get("daily_text"), :author => store.get("daily_author"), :book => store.get("daily_book"), :_id => store.get("daily_id")}
  else
    return Quote.find(store.get("daily_id"))
  end

  return dailyQuote

end


def getRandomQuote

  # TODO : Random
  quotes = Quote.all
  randomQuote = nil
  loop do
    randomQuote = quotes.sample
    break if randomQuote.hidden == false && randomQuote.text.length <= 400
  end

  return randomQuote

end

get '/quote/daily' do

  dailyQuote = getDailyQuote('json')

  content_type :json
  dailyQuote.to_json
end

get '/quote/daily/reset' do
  redirect '/' if session[:user].nil? || session[:user][:role] != "admin"
  store.set('daily_date', '1900, 12, 12')
  redirect '/quote/daily'
end

get '/quote/random' do
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  @quote = getRandomQuote
  slim :quote, :locals=>{:title => "Citations - #{@quote.author.name}, #{@quote.book.name}"}
end

get '/quote/best' do
  @quotes = Quote.gt(starred: 0).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:starred).page(params[:page])
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  slim :index, :locals=>{:title => "Citations - Meilleures citations", :h1 => "Meilleures citations"}
end

get '/quote/:id' do |id|
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  @quote = Quote.find(id)
  redirect '/' if @quote.hidden && session[:user] != @quote.user
  slim :quote, :locals=>{:title => "Citations - #{@quote.author.name}, #{@quote.book.name}"}
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

put '/quote/:id/star' do |id|
  if session[:user].starred.nil? then
    User.find(session[:user]._id).push(:starred, id)
    session[:user].starred = [id]
  else
    unless session[:user].starred.include?(id) then
      User.find(session[:user]._id).push(:starred, id)
      session[:user].starred.push(id)
    end
  end
  Quote.find(id).inc(:starred, 1)
  200
end

put '/quote/:id/unstar' do |id|
  session[:user].starred.delete_at(session[:user].starred.index(id))
  User.find(session[:user]._id).pull(:starred, id)
  Quote.find(id).inc(:starred, -1)
  200
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
  if session[:user] != quote.user && session[:user][:role].nil? && session[:user][:role] != 'admin'
    status 401
    return {:edit => "ko"}.to_json
  end
  quote[:text] = params[:quote]["text"]
  quote[:hidden] = !params[:quote]["hidden"].nil?
  quote.save
  return {:delete => "ok"}.to_json
end

get '/?' do
  @quotes = Quote.or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  slim :index
end
