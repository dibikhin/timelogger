require 'haml'
require 'sinatra'
require 'mongo'
require 'time'

require "./core/record_manager"
require "./core/user_manager"
require "./entities"
require "./helpers"

set :ticket, 'ticket'

get '/' do
	redirect '/timelog'
end

get '/timelog' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil?
		@title = "Timelog"
    @username = user.name
    today_records = RecordManager.get_today_records(user.login) # Mongo::ConnectionFailure
      .map {|recDoc| Record.new(recDoc)}
      .sort_by {|rec| rec.startUtc}.reverse!

    haml :timelog,
         :locals => {:state => user.state, :currentRecordId => user.currentRecordId, :todayRecords => today_records}
	else
    redirect '/logon'
  end
end

#   Timelog controller

post '/start' do
	user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 0 # can start
      UserManager.set_state(user.login, 1) # can control
			RecordManager.start_new_record(user.login)
			redirect '/timelog'
	end
end

post '/begin_save' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 1 # can control
    UserManager.set_state(user.login, 2)  # should save
    redirect '/timelog'
  end
end

post '/end_save' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 2 # should save == saving
    task_id = params[:task_id].strip
    description = params[:description].strip

    if !any_nil_or_empty?(task_id, description)
      RecordManager.end_record(user.login, user.currentRecordId, task_id, description)
      UserManager.set_state(user.login, 1) # can control == recording
      RecordManager.start_new_record(user.login)
    end
  end
  redirect '/timelog'
end

get '/pause' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 1 # can control == recording
    RecordManager.pause(user.currentRecordId)
    UserManager.set_state(user.login, 4)
    redirect '/timelog'
  end
end

post '/resume' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 4 # paused
    RecordManager.resume(user.currentRecordId)
    UserManager.set_state(user.login, 1) # can control == recording
    redirect '/timelog'
  end
end

get '/skip' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == 1 # can control
    RecordManager.end_record(user.login, user.currentRecordId)
    #UserManager.set_state(user.name, 1)
    RecordManager.start_new_record(user.login)
    redirect '/timelog'
  end
end

get '/continue' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? #&& user.state == 2, 3  # should save or should end == saving or ending
    UserManager.set_state(user.login, 1)  # can control == recording
    redirect '/timelog'
  end
end

# 	Account controller

get '/logon' do
	user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil?
		redirect '/timelog'
	else
	  @title = "Log On"
	  haml :logon
  end
end

post '/logon' do
	login = params[:login].strip
	password = params[:password].strip
  if !any_nil_or_empty?(login, password)
    user = UserManager.get(login)
    if !user.nil? && Helpers.auth_ok?(user, login, password)
      response.set_cookie(settings.ticket, {:value => Helpers.get_ticket(user.login, password), :path => '/'})
      redirect '/timelog'
    else
      redirect '/logon'
    end
  else
    redirect '/logon'
  end
end

get '/logoff' do
	cookie_value = request.cookies[settings.ticket]
  if !(cookie_value.nil? || cookie_value.empty?)
    response.set_cookie(settings.ticket, nil)
  end
  redirect '/logon'
end

get '/register' do
	user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil?
		@title = "Register"
		haml :register
	else
	  redirect '/timelog'
  end
end

post '/register' do
	username, login, email  = params[:username], params[:login], params[:email]
  password, confirmPassword = params[:password], params[:confirmPassword]

	# params strip # params.each { |key, value| puts value } # blank?(username, login, email, password, confirmPassword)

  if password == confirmPassword && UserManager.add(login, password, username, email)
      response.set_cookie(settings.ticket, {:value => Helpers.get_ticket(login, password), :path => '/'})
      redirect '/timelog'
  else
    redirect '/register'
  end
end

get '/profile' do
	user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil?
		@title = "Profile"
    @username = user.name
		haml :profile, :locals => {:user => user}
	else
	  redirect '/register'
  end
end

post '/profile' do
	user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil?
		users.update(
			{'_id' => user.login},
			{'$set' => {
				'RedmineTimeEntriesUrl'=> params[:redmineTimeEntriesUrl],
				'RedmineApiKey'=> params[:redmineApiKey],
				'RedmineDefaultActivityId'=> params[:redmineDefaultActivityId]}})
		redirect '/timelog'
  else
    redirect '/logon'
  end
end

#        BSON::ObjectId('')
#
#        CanStartRecording = 0
#        CanSaveRecordOrEndRecording = 1
#        ShouldSaveRecord = 2
#        ShouldSaveRecordAndEndRecording = 3
#        Paused = 4