require 'haml'
require 'sinatra'
require 'mongo'
require 'time'

require "./core/record_manager"
require "./core/user_manager"
require "./entities"
require "./auth_helpers"
require './helpers'

set :ticket, 'ticket'

get '/' do
  redirect '/timelog'
end

get '/timelog' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket]) # Mongo::ConnectionFailure
  if user.nil?
    redirect '/logon'
  else
    @title = "Timelog"
    @username = user.name # Mongo::ConnectionFailure below
    today_records = RecordManager.get_today_records(user.login).sort_by { |rec| rec.startUtc }.reverse!

    haml :timelog,
         :locals => {
             :state => user.state,
             :currentRecordId => user.currentRecordId,
             :todayRecords => today_records,
             :utc_offset => user.utc_offset}
  end
end

#   Timelog controller

post '/start' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::CAN_START
    UserManager.set_state(user.login, RecorderState::RECORDING)
    RecordManager.start_new_record(user.login)
    redirect '/timelog'
  end
end

post '/begin_save' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::RECORDING
    UserManager.set_state(user.login, RecorderState::SAVING)
    redirect '/timelog'
  end
end

post '/end_save' do
  task_id, description = params[:task_id].strip, params[:description].strip

  unless Helpers.any_nil_or_empty?(description)
    user = UserManager.get_authenticated(request.cookies[settings.ticket])
    if !user.nil? && user.state == RecorderState::SAVING
      RecordManager.end_record(user, task_id, description)
      UserManager.set_state(user.login, RecorderState::RECORDING)
      RecordManager.start_new_record(user.login)
    end
  end
  redirect '/timelog'
end

get '/begin_stop' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::RECORDING
    UserManager.set_state(user.login, RecorderState::STOPPING)
    redirect '/timelog'
  end
end

post '/end_stop' do
  task_id, description = params[:task_id].strip, params[:description].strip
  unless Helpers.any_nil_or_empty?(description)
    user = UserManager.get_authenticated(request.cookies[settings.ticket])
    if !user.nil? && user.state == RecorderState::STOPPING
      RecordManager.end_record(user, task_id, description)
      UserManager.set_state(user.login, RecorderState::CAN_START)
    end
  end
  redirect '/timelog'
end

get '/pause' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::RECORDING
    RecordManager.pause(user.currentRecordId)
    UserManager.set_state(user.login, RecorderState::PAUSED)
    redirect '/timelog'
  end
end

post '/resume' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::PAUSED
    RecordManager.resume(user.currentRecordId)
    UserManager.set_state(user.login, RecorderState::RECORDING)
    redirect '/timelog'
  end
end

get '/skip' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::RECORDING
    RecordManager.end_record(user)
    RecordManager.start_new_record(user.login)
  end
  redirect '/timelog'
end

get '/skip_on_stop' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && user.state == RecorderState::STOPPING
    RecordManager.end_record(user)
    UserManager.set_state(user.login, RecorderState::CAN_START)
  end
  redirect '/timelog'
end

get '/continue' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if !user.nil? && (RecorderState::SAVING..RecorderState::STOPPING) === user.state
    UserManager.set_state(user.login, RecorderState::RECORDING)
  end
  redirect '/timelog'
end

# 	Account controller

get '/logon' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if user.nil?
    @title = "Log On"
    haml :logon
  else
    redirect '/timelog'
  end
end

post '/logon' do
  login, password = params[:login].strip, params[:password].strip
  unless Helpers.any_nil_or_empty?(login, password)
    user = UserManager.get(login)
    if !user.nil? && AuthHelpers.auth_ok?(user, login, password)
      response.set_cookie(settings.ticket, {:value => AuthHelpers.get_ticket(user.login, password), :path => '/'})
      redirect '/timelog'
      return
    end
  end
  redirect '/logon'
end

get '/logoff' do
  cookie_value = request.cookies[settings.ticket]
  unless cookie_value.nil? || cookie_value.empty?
    response.set_cookie(settings.ticket, nil)
  end
  redirect '/logon'
end

get '/register' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if user.nil?
    @title = "Register"
    haml :register
  else
    redirect '/timelog'
  end
end

post '/register' do
  username, login, email = params[:username].strip, params[:login].strip, params[:email].strip
  password, confirm_password = params[:password].strip, params[:confirmPassword].strip

  unless Helpers.any_nil_or_empty?(username, login, email, password, confirm_password)
    if password == confirm_password && UserManager.add(login, password, username, email)
      response.set_cookie(settings.ticket, {:value => AuthHelpers.get_ticket(login, password), :path => '/'})
      redirect '/timelog'
      return
    end
  end
  redirect '/register'
end

get '/profile' do
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  if user.nil?
    redirect '/register'
  else
    @title = "Profile"
    @username = user.name
    haml :profile, :locals => {:user => user}
  end
end

post '/profile' do
  time_entries_url, api_key, default_activity_id = params[:redmineTimeEntriesUrl], params[:redmineApiKey], params[:redmineDefaultActivityId]
  user = UserManager.get_authenticated(request.cookies[settings.ticket])
  unless user.nil?
    UserManager.set_redmine_settings(user.login, time_entries_url, api_key, default_activity_id)
    redirect '/timelog'
    return
  end
  redirect '/logon'
end