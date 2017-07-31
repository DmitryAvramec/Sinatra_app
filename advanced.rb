require 'sinatra'
require 'sinatra/activerecord'
require 'rest_client'
require 'json'
require './models/user.rb'
require './helpers.rb'
require 'dotenv/load'
require 'omniauth'
require 'omniauth-github'
require 'rake'
require 'pry'
require 'yaml'
require 'jwt'

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
  current_user_id = JWT.decode(session['user'], nil, false)[0].to_i
  current_user = User.find(current_user_id)
  current_count = JWT.decode(session['user_count'], nil, false)[0].to_i
  current_user.update(count: current_count) if current_count > current_user.count
  sort_users = User.order(count: :desc)
  refresh_step
  erb :profile, locals: { user: current_user, users: sort_users, current_score: current_count }
end

post '/submit' do
  current_step = JWT.decode(session['number'], nil, false)[0].to_i
  result = DATA[current_step]
  right_answer = result["right_answer"]
  current_count = JWT.decode(session['user_count'], nil, false)[0].to_i
  current_count += 1 if params[:user_input] == right_answer
  current_step += 1
  session['number'] = JWT.encode(current_step.to_s, nil, 'none')
  session['user_count'] = JWT.encode(current_count.to_s, nil, false)
  redirect '/profile' if current_step == DATA.size   
  redirect'/step'
end

get '/step' do
  protected!
  current_step = JWT.decode(session['number'], nil, false)[0].to_i
  result = DATA[current_step]
  question = result["question"]
  erb :step1, locals: { question: question, number: current_step }
end

get '/logout' do
    destroy_session
    redirect '/'
end