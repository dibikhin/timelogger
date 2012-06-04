require "./auth_helpers"
require "./core/user_provider"

class UserManager
  def self.add(login, password, username, email)
    found_user = UserProvider.get(login)
    if found_user.nil? # todo push down user_doc to UserProvider.add
      user_doc = {'_id' => login, 'Password' => AuthHelpers.based64_md5(password),
                  'Name' => username, 'Email' => email, 'State' => RecorderState::CAN_START} # todo pull up state
      UserProvider.add(user_doc)
      return true
    end
  end

  def self.get(login)
    UserProvider.get(login)
  end

  def self.set_state(login, state)
    UserProvider.set_state(login, state)
  end

  def self.get_authenticated(cookie) # todo need more any_nil_or_empty? on objects
    unless cookie.nil?
      ticket = cookie.split(':') #  todo clarify cookie-ticket-token magic
      if ticket.size == 2
        login, cookie_token = ticket[0], ticket[1]
        user = UserProvider.get(login)
        if !user.nil? && cookie_token == user.password
          user
        end
      end
    end
  end

  def self.set_redmine_settings(login,time_entries_url, api_key, default_activity_id)
    UserProvider.set_redmine_settings(login, time_entries_url, api_key, default_activity_id)
  end
end