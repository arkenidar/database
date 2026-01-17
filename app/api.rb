require 'sinatra/base'
require 'sinatra/json'
require 'json'

class BlogAPI < Sinatra::Base
  helpers Sinatra::JSON

  # Default hosts for local development; override via PERMITTED_HOSTS env var
  DEFAULT_PERMITTED_HOSTS = %w[127.0.0.1 localhost].freeze

  configure do
    set :show_exceptions, false
    # Allow reverse proxy hosts (comma-separated in ENV, or use defaults)
    hosts = ENV.fetch('PERMITTED_HOSTS', DEFAULT_PERMITTED_HOSTS.join(',')).split(',').map(&:strip)
    set :host_authorization, permitted_hosts: hosts
  end

  before do
    content_type :json
  end

  # Parse JSON body for POST/PUT requests
  before do
    if request.content_type&.include?('application/json') && !request.body.read.empty?
      request.body.rewind
      @json_body = JSON.parse(request.body.read, symbolize_names: true)
    end
  end

  # Error handling
  error ActiveRecord::RecordNotFound do
    status 404
    json error: 'Record not found'
  end

  error ActiveRecord::RecordInvalid do |e|
    status 422
    json error: 'Validation failed', details: e.record.errors.full_messages
  end

  error JSON::ParserError do
    status 400
    json error: 'Invalid JSON'
  end

  # Root
  get '/' do
    json message: 'Blog API', version: '1.0', endpoints: {
      authors: '/authors',
      posts: '/posts',
      comments: '/comments'
    }
  end

  # ============ AUTHORS ============

  get '/authors' do
    authors = Author.all.map(&:to_h)
    json authors
  end

  get '/authors/:id' do
    author = Author.find(params[:id])
    json author.to_h.merge(posts: author.posts.map(&:to_h))
  end

  post '/authors' do
    author = Author.create!(@json_body.slice(:name, :email, :bio))
    status 201
    json author.to_h
  end

  put '/authors/:id' do
    author = Author.find(params[:id])
    author.update!(@json_body.slice(:name, :email, :bio))
    json author.to_h
  end

  delete '/authors/:id' do
    author = Author.find(params[:id])
    author.destroy!
    status 204
  end

  # ============ POSTS ============

  get '/posts' do
    posts = if params[:status] == 'published'
              Post.published.recent
            elsif params[:status] == 'drafts'
              Post.drafts.recent
            else
              Post.recent
            end
    json posts.map(&:to_h)
  end

  get '/posts/:id' do
    post = Post.find(params[:id])
    json post.to_h.merge(comments: post.comments.map(&:to_h))
  end

  post '/posts' do
    post = Post.create!(@json_body.slice(:author_id, :title, :body, :published_at))
    status 201
    json post.to_h
  end

  put '/posts/:id' do
    post = Post.find(params[:id])
    post.update!(@json_body.slice(:title, :body, :published_at))
    json post.to_h
  end

  post '/posts/:id/publish' do
    post = Post.find(params[:id])
    post.publish!
    json post.to_h
  end

  post '/posts/:id/unpublish' do
    post = Post.find(params[:id])
    post.unpublish!
    json post.to_h
  end

  delete '/posts/:id' do
    post = Post.find(params[:id])
    post.destroy!
    status 204
  end

  # ============ COMMENTS ============

  get '/comments' do
    comments = if params[:post_id]
                 Comment.where(post_id: params[:post_id])
               else
                 Comment.all
               end
    json comments.map(&:to_h)
  end

  get '/comments/:id' do
    comment = Comment.find(params[:id])
    json comment.to_h
  end

  post '/comments' do
    comment = Comment.create!(@json_body.slice(:post_id, :author_id, :commenter_name, :body))
    status 201
    json comment.to_h
  end

  put '/comments/:id' do
    comment = Comment.find(params[:id])
    comment.update!(@json_body.slice(:body))
    json comment.to_h
  end

  delete '/comments/:id' do
    comment = Comment.find(params[:id])
    comment.destroy!
    status 204
  end
end
