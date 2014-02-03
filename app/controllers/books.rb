# encoding: utf-8

get '/book/find/author/:author/book/:book' do |author, book|
  content_type :json
  Book.where(author: author, name: Regexp.new(book, true)).limit(10).to_json
end

get '/books' do
  @books = Book.all.asc(:name)
  slim :books, :locals=>{:title => "Citations - Livres"}
end

get '/book/:id' do |id|
  @book = Book.find(id)
  @quotes = Quote.where(book: id).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])
  slim :book, :locals=>{:title => "Citations - #{@book.author.name}, #{@book.name}"}
end