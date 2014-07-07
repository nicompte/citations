# encoding: utf-8

get '/search' do
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  q = params[:q]
  @authors = Author.where(name: Regexp.new(q, true)).asc(:name)
  @books = Book.where(name: Regexp.new(q, true)).asc(:name)
  @quotes = Quote.where(text: Regexp.new(q, true)).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  @query = q
  slim :search
end

get '/about' do
  slim :about
end

get '/ping' do
  'ok'
end

not_found do
  'Page non trouvée.'
end

error do
  'Erreur - ' + env['sinatra.error']
end
