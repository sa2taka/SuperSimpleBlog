# frozen_string_literal: false

require 'rubygems'
require 'sinatra'
require 'sinatra/base'
require 'active_record'

require_relative './models'

class SuperSimpleBlog < Sinatra::Base
  enable :sessions

  get '/login' do
    unless session[:userid]&.nil?
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
      cookies['sessionid'] = user.sessionid

      redirect '/'
    else
      @message = 'ユーザー名またはパスワードが間違っています'
      return erb :login
    end
  end
end
