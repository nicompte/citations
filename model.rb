require 'mongoid'

class Author
  include Mongoid::Document
  field :name
  has_many :quotes
  has_many :books
end

class Book
  include Mongoid::Document
  field :name
  field :year
  has_many :quote
  belongs_to :author
end

class Quote
  include Mongoid::Document
  field :text
  belongs_to :book
  belongs_to :author
end

class User
  include Mongoid::Document
  field :name
  field :password
end