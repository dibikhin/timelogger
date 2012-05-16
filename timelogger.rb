require 'haml'
require 'sinatra'
require 'mongo'
require 'digest'
require 'base64'

set :ticket, 'ticket'

helpers do
	def cookies_ok?
		cookie = request.cookies[settings.ticket]
		if !cookie.nil? # any_nil_or_empty
			ticket = cookie.split(':')
			if !ticket.nil? # any_nil_or_empty
				login = ticket[0]
				token = ticket[1]
				# any_nil_or_empty?(login, token)
				userDoc = get_users.find_one('_id' => login)
				if !userDoc.nil? # any_nil_or_empty
					user = User.new(userDoc)
					if !user.nil?
						@username = user.name # bad magic
						@login = user.login
						return token == get_token(user.login, user.password)
					end
				end
			end
		end
		false
	end

	def get_users
		return @users if @users
		@users = Mongo::Connection.from_uri(
#			"mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog")
			"mongodb://localhost:27017/Timelog")
			.db("Timelog").collection("Users")
		@users
	end

	# auth helpers

	def based64md5(string)
		Base64.strict_encode64(Digest::MD5.digest(string))
	end

	def auth_ok?(user, login, password)
		user.login == login && user.password == based64md5(password)
	end

	def get_token(login, password)
		based64md5(login + password)
	end

	# param helpers

	def nil_or_empty?(param)
		param.nil? || param.empty?
	end

	def any_nil_or_empty?(params)
		nil_or_empty?(params) || params.any? {|key, value| nil_or_empty?(value)}
	end
end

get '/' do
	redirect '/timelog'
end

get '/timelog' do
	if cookies_ok?
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
	login = params[:login].strip
	password = params[:password].strip

	if !any_nil_or_empty?(:login => login, :password => password)
		userDoc = get_users.find_one('_id' => params[:login])
		if !userDoc.nil? # any_nil_or_empty?
			user = User.new(userDoc)
			if auth_ok?(user, login, password)
				response.set_cookie(settings.ticket,
					{:value => user.login + ':' + get_token(user.login, user.password), :path => '/'})
				redirect '/timelog'
			end
		end
	end

	redirect '/logon'
end

get '/logoff' do
	cookie = request.cookies[settings.ticket]
	if !cookie.nil?
		response.set_cookie(settings.ticket, false)
	end
	redirect '/logon'
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
	username = params[:username]
	login = params[:login]
	email = params[:email]
	password = params[:password]
	confirmPassword = params[:confirmPassword]

	# params strip
	# params.each { |key, value| puts value }
	# blank?(username, login, email, password, confirmPassword)

	if password == confirmPassword
		doc = {'_id' => login, 'Password' => based64md5(password),
			'Name' => username, 'Email' => email, 'State' => 0}

		get_users.insert(doc)
		response.set_cookie(settings.ticket,
			{:value => login + ':' + get_token(login, based64md5(password)), :path => '/'})
		redirect '/timelog'
	else
		redirect '/register'
	end
end

get '/profile' do
	if cookies_ok?
		userDoc = get_users.find_one("_id" => @login) # bad magic
		@title = "Profile"
		haml :profile, :locals => {:user => User.new(userDoc)}
	else
		redirect '/register'
	end
end

post '/profile' do
	if cookies_ok?
		get_users.update(
			{'_id' => @login},
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
	attr_reader :login, :password, :name, :email, :state,
		:redmineTimeEntriesUrl, :redmineApiKey, :redmineDefaultActivityId

	def initialize(doc)
		@login = doc['_id']
		@password = doc['Password']
		@name = doc["Name"]
		@email = doc["Email"]
		@state = doc["State"]
		@redmineTimeEntriesUrl = doc["RedmineTimeEntriesUrl"]
		@redmineApiKey = doc["RedmineApiKey"]
		@redmineDefaultActivityId = doc["RedmineDefaultActivityId"]
	end
end
