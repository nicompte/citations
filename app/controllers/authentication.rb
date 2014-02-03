# encoding: utf-8

post '/login' do
  content_type :json
  user = User.where(name: params[:user])
  if user.exists? && user.first.password == Digest::MD5.hexdigest(params[:password])
    if user.first.validated == false
      return {:login => "ko", :message => "Veuillez valider votre email."}.to_json
    end
    session[:user] = user.first
    return {:login => "ok"}.to_json
  else
    status 401
    return {:login => "ko"}.to_json
  end
end

get '/logout' do
  session[:user] = nil
  redirect "/"
end

post '/register' do

  alreadyExisting = User.or( {name: params[:user]["name"]}, {email: params[:user]["email"]} )
  redirect '/' unless alreadyExisting.nil? or !alreadyExisting.exists?

  params[:user].except! "password-again"
  params[:user]["validated"] = false
  params[:user]["token"] = SecureRandom.hex(15)
  params[:user]["password"] = Digest::MD5.hexdigest params[:user]["password"]
  user = User.create(params[:user])
  url = "http://citations.barbotte.net/user/#{user._id}/token/#{params[:user]['token']}"

  mail = Mail.new

  mail.to = params[:user]["email"]
  mail.from = 'no-reply@barbotte.net'
  mail.subject = "Validation de l'email citations.barbotte.net"
  mail.content_type = 'text/html; charset=UTF-8'
  mail.body = Slim::Template.new('./views/register-mail.slim').render([{:url => url, :name => params[:user]["name"]}])

  mail.deliver!

  redirect '/'
end

get '/user/:id/token/:token' do |user, token|
  user = User.find(user)
  if user.token == token
    user.validated = true
    user.save
  end
  redirect '/'
end