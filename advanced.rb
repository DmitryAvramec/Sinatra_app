require 'sinatra'
require 'sinatra/activerecord'
require 'rest_client'
require 'json'
require './models/user.rb'
require 'dotenv/load'
require 'omniauth'
require 'omniauth-github'
require 'rake'
require 'pry'
require 'yaml'
require 'jwt'

signing_key_path = File.expand_path("../app.rsa", __FILE__)
verify_key_path = File.expand_path("../app.rsa.pub", __FILE__)

rsa_private = ""
rsa_public = ""

File.open(signing_key_path) do |file|
  rsa_private = OpenSSL::PKey.read(file)
end

File.open(verify_key_path) do |file|
  rsa_public = OpenSSL::PKey.read(file)
end

set :rsa_private, rsa_private
set :rsa_public, rsa_public

CLIENT_ID = ENV['CLIENT_ID']
CLIENT_SECRET = ENV['CLIENT_SECRET_ID']
DATA = YAML.load(File.read('./config/test.yml'))

enable :sessions

configure do
  set :sessions, true
  set :inline_templates, true
end

use OmniAuth::Builder do
  provider :github, CLIENT_ID, CLIENT_SECRET
end

helpers do
  def my_encode text
    JWT.encode text.to_s, settings.rsa_private, 'RS256'
  end

  def my_decode text
    JWT.decode(text, settings.rsa_public, true, { :algorithm => 'RS256' })[0].to_i
  end

  def protected!
    return unless authorized?
    redirect '/login'
  end

  def authorized?
    session['token'].nil?
  end

  def create_session user_id, token
    session['user_count'] = my_encode('0')
    session['number'] = my_encode('0')
    session['user'] = my_encode(user_id.to_s)
    session['token'] = my_encode(token.to_s)
  end

  def refresh_step
    session['user_count'] = my_encode('0')
    session['number'] = my_encode('0')
  end

  def destroy_session
    session['token']= nil
  end
end

get '/' do
  protected!
  redirect '/step'
end

get '/login' do
  erb :login
end

get '/auth/:provider/callback' do
  token = request.env['omniauth.auth'][:credentials][:token]
  info = request.env['omniauth.auth'][:info]
  name = info[:name] ? info[:name] : info[:nickname]
  git_id = request.env['omniauth.auth'][:uid]
  create = { name: name, gitid: git_id }
  current_user = User.find_or_create_by(gitid: git_id) 
  current_user.update(name: name) if current_user.name != name
  create_session(current_user.id, token)
  redirect'/step'
end

get '/profile' do
  current_user_id = my_decode(session['user'])
  current_user = User.find(current_user_id)
  current_count = my_decode(session['user_count'])
  current_user.update(count: current_count) if current_count > current_user.count
  sort_users = User.order(count: :desc)
  refresh_step
  erb :profile, locals: { user: current_user, users: sort_users, current_score: current_count }
end

post '/submit' do
  current_step = my_decode(session['number'])
  result = DATA[current_step]
  right_answer = result["right_answer"]
  current_count = my_decode(session['user_count'])
  current_count += 1 if params[:user_input] == right_answer
  current_step += 1
  session['number'] = my_encode(current_step)
  session['user_count'] = my_encode(current_count)
  redirect '/profile' if current_step == DATA.size   
  redirect'/step'
end

get '/step' do
  protected!
  current_step = my_decode(session['number'])
  result = DATA[current_step]
  question = result["question"]
  erb :step1, locals: { question: question, number: current_step }
end

get '/logout' do
    destroy_session
    redirect '/'
end