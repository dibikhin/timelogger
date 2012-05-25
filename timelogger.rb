require 'haml'
require 'sinatra'
require 'mongo'
require 'digest'
require 'base64'
require 'time'

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
						@username 			= user.name 		# bad magic started
						@state				= user.state
						@login				= user.login
						@currentRecordId 	= user.currentRecordId
						return token == get_token(user.login, user.password)
					end
				end
			end
		end
		false
	end

	# User manager

	def set_state(login, state)
		provider_set_state(login, state)
	end

	# User provider

	def get_users
		return @users if @users
		@users = Mongo::Connection.from_uri(
			"mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog")
			.db("Timelog").collection("Users") # "mongodb://localhost:27017/Timelog"
		@users
	end

	def provider_set_state(login, state)
		get_users.update({'_id' => login}, {'$set' => {'State' => state}})
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

	#	Record manager
	def get_today_records(login)
		time = Time.now		# Wed May 23 00:00:00 +0400 2012 -> Tue May 22 20:00:00 UTC 2012
		get_record_list(login, Time.local(time.year, time.month, time.day).utc, Time.now.utc)
	end

	#	Record provider
	def get_records
		return @records if @records
		@records = Mongo::Connection.from_uri(
			"mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog")
			.db("Timelog").collection("Records")	# "mongodb://localhost:27017/Timelog"
		@records
	end

	def get_record_list(login, startUtc, endUtc)
		get_records.find({'UserId' => login, 'StartUtc' => {'$gte' => startUtc, '$lte' => endUtc}})
	end
end

get '/' do
	redirect '/timelog'
end

get '/timelog' do
	if cookies_ok?
		@title = "Timelog"
		haml :timelog, :locals => {:state => @state, :currentRecordId => @currentRecordId,
			:todayRecords => get_today_records(@login).map{ |recDoc| Record.new(recDoc) }
				.sort_by {|rec| rec.startUtc}.reverse!}
	else
		redirect '/logon'
	end
end

#   Timelog controller

post '/start' do
	if cookies_ok?
		if state == 0
			set_state(@login, 1)
			start_new_record @login

			redirect '/timelog'
		end
	end
end

# 	Account controller

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

#	Entities	#

class User
	attr_reader :login, :password, :name, :email, :state, :currentRecordId,
		:redmineTimeEntriesUrl, :redmineApiKey, :redmineDefaultActivityId

	def initialize(doc)
		@login = doc['_id']
		@password = doc['Password']
		@name = doc["Name"]
		@email = doc["Email"]
		@state = doc["State"]
		@currentRecordId = doc['CurrentRecordId']
		@redmineTimeEntriesUrl = doc["RedmineTimeEntriesUrl"]
		@redmineApiKey = doc["RedmineApiKey"]
		@redmineDefaultActivityId = doc["RedmineDefaultActivityId"]
	end
end

class Record
	attr_reader :id, :startUtc, :endUtc, :taskId, :description, :isFinished, :duration, :lastPauseStartUtc

	def initialize(doc)
		@id = doc['_id']
		@userId = doc['UserId']
		@startUtc = doc['StartUtc']
		@endUtc = doc['EndUtc']
		@taskId = doc['TaskId']
		@description = doc['Description']
		@isFinished = doc['IsFinished']
		@lastPauseStartUtc = doc['LastPauseStartUtc']

		# '00:26:52.6284490' -> Wed May 23 00:26:52 +0400 2012 -> 1612
		durationString = doc['TotalPausedDuration']
		if !durationString.nil?
			totalPausedTime = Time.parse(durationString)
			@totalPausedDuration =  totalPausedTime.hour*60 + totalPausedTime.min*60 + totalPausedTime.sec
		end

		if @startUtc.nil? || @endUtc.nil?
			@duration = nil
		elsif !@totalPausedDuration.nil?
			@duration = Time.at((@endUtc - @startUtc) - @totalPausedDuration).utc
		else
			@duration = Time.at(@endUtc - @startUtc).utc	# 1356 -> Thu Jan 01 00:22:36 UTC 1970
		end
	end
end

# Time.at(Time.now.utc - Time.utc(2012, 5, 21, 17, 30)).utc
# Time.at(dur).utc.strftime('%H:%M:%S')  # 1612 -> 00:26:52
#	- if !todayRecords.nil?
#		%table
#		- todayRecords.each do |record|
#			%tr
#				%td= record.startUtc
#        [BsonIgnore] public TimeSpan? Duration
# BSON::ObjectId('')
#
#        CanStartRecording = 0
#        CanSaveRecordOrEndRecording = 1
#        ShouldSaveRecord = 2
#        ShouldSaveRecordAndEndRecording = 3
#        Paused = 4
