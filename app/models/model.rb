require 'mongoid'
require 'kaminari/sinatra'

class Author
  include Mongoid::Document
  field :name, type: String
  has_many :quotes
  has_many :books
end

class Book
  include Mongoid::Document
  paginates_per 25
  field :name, type: String
  field :year, type: Integer
  has_many :quote
  belongs_to :author
end

class Quote
  include Mongoid::Document
  field :text, type: String
  field :hidden, type: Boolean
  field :starred, type: Integer
  belongs_to :book
  belongs_to :author
  belongs_to :user
end

class User
  include Mongoid::Document
  field :name, type: String
  field :password, type: String
  field :email, type: String
  field :isValidated, type: Boolean
  field :token, type: String
  field :starred, type: Array
  has_many :quotes
end
