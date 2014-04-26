# encoding: utf-8

uri = URI.parse(ENV["REDISTOGO_URL"])
store = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

get '/quote' do
  redirect '/' if session[:user].nil?
  slim :new_quote
end

get '/quote/daily' do
  today = Time.new
  lastQuote = Date.strptime(store.get("daily_date"), "%Y, %m, %d")
  if lastQuote.nil? || today.year > lastQuote.year || today.month > lastQuote.month || today.day > lastQuote.day then
    quotes = Quote.all
    loop do
      @quote = quotes.sample
      sameAuthor = @quote.author.name == store.get("daily_author")
      break if !sameAuthor && (@quote.hidden == false && @quote.text.length <= 400)
    end
    randomQuote = {:text => @quote.text, :author => @quote.author.name, :book=>@quote.book.name}
    store.set("daily_text", @quote.text)
    store.set("daily_author", @quote.author.name)
    store.set("daily_book", @quote.book.name)
    store.set("daily_date", Time.new.strftime("%Y, %m, %d"))
  else
    randomQuote = {:text => store.get("daily_text"), :author => store.get("daily.author"), :book => store.get("daily_book")}
  end

  content_type :json
  randomQuote.to_json
end

get '/quote/daily/reset' do
  redirect '/' if session[:user].nil? || session[:user][:role] != "admin"
  store.set('daily_date', '1900, 12, 12')
  redirect '/quote/daily'
end

get '/quote/random' do
  #count = Quote.or( {hidden: false}, {hidden: true, user: session[:user]} ).count
  quotes = Quote.all
  loop do
    @quote = quotes.sample
    break if @quote.hidden == false && @quote.text.length <= 400
  end
  slim :quote, :locals=>{:title => "Citations - #{@quote.author.name}, #{@quote.book.name}"}
end

get '/quote/:id' do |id|
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
  slim :index
end