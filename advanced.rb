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
  session['number'] = 0
  session['user_count'] = 0
  erb :login
end

get '/auth/:provider/callback' do
  info = request.env['omniauth.auth'][:info]
  name = info[:name] ? info[:name] : info[:nickname]
  git_id = request.env['omniauth.auth'][:uid]
  create = { name: name, gitid: git_id }
  current_user = User.find_or_create_by(gitid: git_id) 
  current_user.update(name: name) if current_user.name != name
  session['user'] = current_user.id
  redirect'/step'
end

get '/profile' do
  current_user = User.find(session['user'])
  current_user.update(count: session['user_count']) if session['user_count'] > current_user.count
  current_score = session['user_count']
  sort_users = User.order(count: :desc)
  session['number'] = 0
  session['user_count'] = 0
  erb :profile, locals: { user: current_user, users: sort_users, current_score: current_score }
end

post '/submit' do
  current_step = session['number']
  result = DATA[current_step]
  right_answer = result["right_answer"]
  session['user_count'] += 1 if params[:user_input] == right_answer
  session['number'] += 1
  redirect '/profile' if session['number'] == DATA.size   
  redirect'/step'
end

get '/step' do
  result = DATA[session['number']]
  question = result["question"]
  erb :step1, locals: { question: question, number: session['number'] }
end

get '/logout' do
    session = {}
    redirect '/'
end