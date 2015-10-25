# encoding: utf-8

get '/admin/*' do
  redirect '/' if session[:user].nil? || session[:user][:role] != "admin"
  pass
end

get '/admin/users' do
  @users = User.all.asc(:name)
  slim :users, :layout => 'layout'
end

post '/admin/author/edit' do
  author = Author.find params[:id]
  author.name = params[:name]
  author.save
  redirect '/authors'
end

post '/admin/book/edit' do
  book = Book.find params[:id]
  book.name = params[:name]
  book.save
  redirect '/books'
end