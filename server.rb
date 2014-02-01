# encoding: utf-8

%w( 
  sinatra slim json kaminari/sinatra padrino-helpers  
  securerandom digest mail
  newrelic_rpm
  mongoid
  )
  .map {|gem| require gem}

# Configuration

use Rack::Deflater
enable :sessions
set :session_secret, ENV['SESSION_SECRET']
register Kaminari::Helpers::SinatraHelpers

configure :development do
  require "better_errors"
  require "binding_of_caller"
  use BetterErrors::Middleware
  BetterErrors.application_root = __dir__
end

Mongoid.load!("config/mongoid.yml", :production)

Mail.defaults do
  delivery_method :smtp, {
    :address   => "smtp.sendgrid.net",
    :port      => 587,
    :domain    => "barbotte.net",
    :user_name => ENV['SENDGRID_USERNAME'],
    :password  => ENV['SENDGRID_PASSWORD'],
    :authentication => 'plain',
    :enable_starttls_auto => true
  }
end

# Load models and routes

Dir["./app/models/*.rb"].each { |file| require file }
Dir["./app/controllers/*.rb"].each { |file| require file }

