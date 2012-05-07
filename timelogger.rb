require 'haml'
require 'sinatra'

set :username,'dobsky'
set :token,'shakenN0tstirr3d'
set :password,'asdf1234'

helpers do
  def authenticated? ; request.cookies[settings.username] == settings.token ; end
end

get '/' do
	redirect '/timelog'
end

get '/timelog' do
	if	authenticated?
		@title = "Timelog"
		haml :index
	else
		redirect '/logon'
	end
end

get '/logon' do
	if	!authenticated?
		@title = "Log On"
		haml :logon
	else
		redirect '/timelog'
	end
end

post '/logon' do
  if params["UserName"] == settings.username && params["Password"] == settings.password
    response.set_cookie(settings.username, {:value => settings.token, :path => '/'}) 
    redirect '/timelog'
  else
    redirect '/logon'
  end
end

get '/logoff' do
	if authenticated?
		response.set_cookie(settings.username, false)
	end
	redirect '/logon'		
end

get '/register' do
	if !authenticated?
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
	if authenticated?
		@title = "Profile"
		haml :profile
	else
		redirect '/register'
	end
end

#require 'digest'
#puts Digest::MD5.hexdigest "My secret1"
# 'mongodb://myusername:myuserpass@flame.mongohq.com:27019
