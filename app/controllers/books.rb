# encoding: utf-8

get '/book/find/author/:author/book/:book' do |author, book|
  content_type :json
  Book.where(author: author, name: Regexp.new(book, true)).limit(10).to_json
end

get '/books' do
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  books = Book.all.asc(:name)
  @books = Hash.new
  ('A'..'Z').each do |letter|
    @books[letter] = books.select{|book| book.name.starts_with?(letter) && book.name != 'Hors livre'}
  end
  slim :books, :locals=>{:title => "Citations - Livres"}, :layout => 'layout'
end

get '/book/:id' do |id|
  @randomQuote = getRandomQuote
  @dailyQuote = getDailyQuote("plain")
  @book = Book.find(id)
  @quotes = Quote.where(book: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :book, :locals=>{:title => "Citations - #{@book.author.name}, #{@book.name}"}, :layout => 'layout'
end
