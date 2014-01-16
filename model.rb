require 'mongoid'

class Author
  include Mongoid::Document
  field :name
  embeds_many :books
end

class Book
  include Mongoid::Document
  field :name
  field :year
  embeds_many :quotes
end

class Quote
  include Mongoid::Document
  field :text
end