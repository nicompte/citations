require 'mongoid'

class Author
  include Mongoid::Document
  field :name, type: String
  has_many :quotes
  has_many :books
end

class Book
  include Mongoid::Document
  field :name, type: String
  field :year, type: Integer
  has_many :quote
  belongs_to :author
end

class Quote
  include Mongoid::Document
  field :text, type: String
  field :hidden, type: Boolean
  belongs_to :book
  belongs_to :author
end

class User
  include Mongoid::Document
  field :name, type: String
  field :password, type: String
end