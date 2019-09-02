# -*- coding: utf-8 -*-
# frozen_string_literal: false

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'rack/protection'
require 'active_record'
require "sinatra/reloader" 
require 'securerandom'

require_relative './models'
require_relative './config.rb'
require_relative './libs/scraper'

class SuperSimpleBlog < Sinatra::Base
  enable :sessions

  configure :development do
    register Sinatra::Reloader
  end

  helpers do
    def csrf_token
      session[:csrf_token]
    end

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
      @message = 'ブログの編集にはユーザーのログインが必要です'
      @path = request.path
      return erb :login
    end

    erb :edit
  end

  get '/posts' do
    unless User.find_by(id: session[:user_id])
      message = 'ブログの閲覧にはユーザーのログインが必要です'
      @path = request.path
      return erb :login
    end

    @posts = User.find(session[:user_id])&.posts.where('title like ?', "#{params[:query]}%" || '%%')
    
    sleep 1 if @posts.exists? # 検索した結果が存在した場合の重い処理

    erb :posts
  end

  get '/posts/:id' do
    unless User.find_by(id: session[:user_id])
      @message = 'ブログの閲覧にはユーザーのログインが必要です'
      @path = request.path
      return erb :login
    end

    @post = User.find(session[:user_id])&.posts.find_by(id: params[:id])

    if @post.nil?
      return erb :unknown
    end

    erb :post
  end

  get '/redirect' do
    @uri = (params[:uri] || '').delete(';')


    if @uri == ''
      @uri = '/'
      return erb :redirect
    end

    if @uri[0] != '/'
      return erb :non_permit
    end

    erb :redirect
  end

  post '/post' do
    unless User.find_by(id: session[:user_id])
      @message = 'ブログの編集にはユーザーの登録が必要です'
      return erb :register
    end

    unless params[:csrf_token] == session[:csrf_token]
      redirect '/edit'
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

    session[:csrf_token] = SecureRandom.base64(64)

    redirect "/posts/#{p.id}"
  end

  get '/report' do
    @message = ''
    erb :report
  end

  post '/report' do
    url = params[:url]

    unless url.start_with?("https://#{$top_level}") || url.start_with?("http://#{$top_level}")
      @message = "urlは http(s)://#{$top_level} から始まっている必要があります"
      return erb :report
    end
    Thread.new { Scraper.scrape($top_level, params[:url]) }.run
    erb :reported
  end

  get '/login' do
    unless (!session[:user_id] || session[:user_id].empty?)
      redirect '/'
    end

    @path = request.path.delete(';')
    @message = ''
    
    erb :login
  end

  post '/login' do
    @path = request.path
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
      session[:csrf_token] = SecureRandom.base64(64)

      redirect "/redirect?uri=#{params[:path]}"
    else
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end
  end

  get '/register' do
    unless (!session[:user_id] || session[:user_id].empty?)
      redirect '/'
    end

    @path = request.path
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
    session[:csrf_token] = SecureRandom.base64(64)
    redirect "/redirect?uri=#{params[:path]}"
  end

  post '/logout' do
    session[:user_id] = ''
    redirect '/'
  end
end
