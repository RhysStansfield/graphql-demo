require 'json'
require 'graphql'

DATA = JSON.parse(File.read(File.join('.', 'data.json')))

Signal.trap("INT") {
  puts "\nToodles"
  sleep 1
  exit
}

class Post
  def self.find(id)
    raw = DATA['posts'].detect { |post| post['id'] == id.to_i }
    new(raw)
  end

  def self.where(**attrs)
    DATA['posts'].select do |post|
      attrs.each_pair.all { |attr, value| post[attr] == value  }
    end.map(&method(:new))
  end

  attr_accessor :id, :title, :body

  def initialize(raw = {})
    self.id = raw['id']
    self.title = raw['title']
    self.body = raw['body']
  end
end

PostType = GraphQL::ObjectType.define do
  name "Post"
  description "A blog post"
  # `!` marks a field as "non-null"
  field :id, !types.ID
  field :title, !types.String
  field :body, !types.String
end

QueryType = GraphQL::ObjectType.define do
  name "Query"
  description "The query root of this schema"

  field :post do
    type PostType
    argument :id, !types.ID
    description "Find a Post by ID"
    resolve ->(obj, args, ctx) { Post.find(args["id"]) }
  end
end

Schema = GraphQL::Schema.define do
  query QueryType
end

loop do
  puts "Query:"
  query = gets.chomp

  puts JSON.pretty_generate(Schema.execute(query))
end
