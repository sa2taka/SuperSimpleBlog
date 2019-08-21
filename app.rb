# frozen_string_literal: false

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'active_record'
require "sinatra/reloader" 

require_relative './models'

class SuperSimpleBlog < Sinatra::Base
  enable :sessions

  configure :development do
    register Sinatra::Reloader
  end

  helpers do
    def user
      User.find_by(id: session[:user_id])
    end

    def html_safe(text)
      Rack::Utils.escape_html(text)
    end
  end

  get '/' do
    erb :top
  end

  get '/edit' do
    unless User.find_by(id: session[:user_id])
      @message = 'ブログの編集にはユーザーの登録が必要です'
      return erb :register
    end

    erb :edit
  end

  post '/post' do
    unless User.find_by(id: session[:user_id])
      @message = 'ブログの編集にはユーザーの登録が必要です'
      return erb :register
    end

    if params[:title]&.length > 64 || params[:text]&.length > 10000
      redirect '/edit'
    end

    user = User.find(session[:user_id])

    id = Base64.urlsafe_encode64(Digest::SHA256.digest(Time.now.to_s + user.id))

    p = Post.new
    if Post.exists? params[:id]
      p = Post.find(params[:id])
    else
      p.id = id
      p.user_id = user.id
    end

    p.title = params[:title]
    p.text = params[:text]

    p.save

    redirect "/posts/#{p.id}"
  end

  get '/login' do
    unless (!session[:user_id] || session[:user_id].empty?)
      redirect '/'
    end
    @message = ''
    erb :login
  end

  post '/login' do
    if params[:name]&.empty? || params[:password]&.empty?
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end

    user = User.new
    begin
      user = User.find(params[:name])
    rescue ActiveRecord::RecordNotFound => e
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end

    if user.authenticate(params[:password])
      session[:user_id] = user.id

      redirect '/'
    else
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end
  end

  get '/register' do
    unless (!session[:user_id] || session[:user_id].empty?)
      redirect '/'
    end
    erb :register
  end

  post '/register' do
    if params[:name]&.empty? || params[:password]&.empty?
      @message = 'ユーザー名、パスワードは必須項目です'
      return erb :register
    end

    if params[:name].length > 16
      @message = 'ユーザー名は16文字以下である必要があります'
      return erb :register
    end

    if User.exists?(id: params[:name])
      @message = 'すでに存在しているユーザー名です'
      return erb :register
    end

    user = User.create(params[:name], params[:password])
    session[:user_id] = user.id
    redirect '/'
  end

  post '/logout' do
    session[:user_id] = ''
    redirect '/'
  end
end
