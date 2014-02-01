# encoding: utf-8

get '/user/:id' do |id|
  @user = User.find(id)
  @quotes = Quote.where(user: @user).or( {hidden: false}, {hidden: true, user: session[:user]} ).desc(:_id).page(params[:page])

  book_id = @quotes.distinct(:book)
  @books = Book.find(book_id).sort_by! { |a| a["name"] }

  auth_id = @quotes.distinct(:author)
  @authors = Author.find(auth_id).sort_by! { |a| a["name"] }

  slim :"user/index"
end