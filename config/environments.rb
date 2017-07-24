configure :develompment do
  data = YAML.load_file('config/database.yml')['development']
  db = OpenStruct.new(data)
  ActiveRecord::Base.establish_connection(
    :adapter => db.adapter,
    :host => db.host,
    :username => db.username,
    :password => db.password,
    :database => db.database,
    :encoding => 'utf8'
  )
end