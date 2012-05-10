require 'haml'
require 'sinatra'
require 'mongo'
require 'digest'
require 'base64'

set :username,'dobsky'
set :token,'shakenN0tstirr3d'
set :password,'asdf1234'
set :ticket, 'ticket'

helpers do
	def cookies_ok?
#		request.cookies[settings.username] == settings.token
		request.cookies[settings.ticket]
	end

	def get_users
		return @users if @users
		@users = Mongo::Connection.from_uri(
			"mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog")
			.db("Timelog").collection("Users")
		@users
	end

	# auth helpers

	def based64md5(string)
		Base64.encode64 Digest::MD5.digest string
	end

	def auth_ok?(user, login, password)
		user.login == login && user.password == based64md5 password
	end

	def get_token(login, password)
		based64md5 login + password
	end

	# param helpers

	def nil_or_empty?(param)
		param.nil? || param.empty?
	end

	def any_nil_or_empty?(params)
		nil_or_empty? params || params.any? {|key, value| nil_or_empty?(value)}
	end
end

get '/' do
	redirect '/timelog'
end

get '/timelog' do
	if	cookies_ok?
		@title = "Timelog"
		haml :index
	else
		redirect '/logon'
	end
end

get '/logon' do
	if cookies_ok?
		redirect '/timelog'
	else
		@title = "Log On"
		haml :logon
	end
end

post '/logon' do
#  if params["UserName"] == settings.username && params["Password"] == settings.password
#    response.set_cookie(settings.username, {:value => settings.token, :path => '/'})
#    redirect '/timelog'
#  else
#    redirect '/logon'
#  end
	if !any_nil_or_empty?(:login => params[:login], :password => params[:password])
		user = User.new(get_users.find_one('_id' => params[:login]))
		if auth_ok?(user, params[:login], params[:password])
			response.set_cookie(settings.ticket, {:value => user.login + ':' + get_token(user.login, user.password), :path => '/'})
			redirect '/timelog'
		else
			redirect '/logon'
		end
	else
		redirect '/logon'
	end
end

get '/logoff' do
	#if cookies_ok?
	#	response.set_cookie(settings.username, false)
	#end
	#redirect '/logon'

	ticket = request.cookies[settings.ticket].split(':')
	# length!
	login = ticket[0]
	token = ticket[1]
	if !any_nil_or_empty(:login => login, :token => token)
		user = User.new(get_users.find_one('_id' => login))
		# ???
	end
end

get '/register' do
	if !cookies_ok?
		@title = "Register"
		haml :register
	else
		redirect '/timelog'
	end
end

post '/register' do
	puts "user name is: " + params[:UserName]
	puts "email is: " + params[:Email]
end

get '/profile' do
	if cookies_ok?
		userDoc = get_users.find_one("_id" => "ivan.dobsky")
		@title = "Profile"
		haml :profile, :locals => {:user => User.new(userDoc)}
	else
		redirect '/register'
	end
end

post '/profile' do
	if cookies_ok?
		get_users.update(
			{'_id' => 'ivan.dobsky'},
			{'$set' => {
				'RedmineTimeEntriesUrl'=> params[:redmineTimeEntriesUrl],
				'RedmineApiKey'=> params[:redmineApiKey],
				'RedmineDefaultActivityId'=> params[:redmineDefaultActivityId]}})
		redirect '/timelog'
	else
		redirect '/logon'
	end
end

class User
	attr_reader :login, :name, :email, :redmineTimeEntriesUrl, :redmineApiKey, :redmineDefaultActivityId

	def initialize(doc)
		@login = doc['_id']
		@name = doc["Name"]
		@email = doc["Email"]
		@redmineTimeEntriesUrl = doc["RedmineTimeEntriesUrl"]
		@redmineApiKey = doc["RedmineApiKey"]
		@redmineDefaultActivityId = doc["RedmineDefaultActivityId"]
	end
end

#require 'digest'
#puts Digest::MD5.hexdigest "My secret1"
#bundle exec ruby timelogger.rb

#30041 anton
