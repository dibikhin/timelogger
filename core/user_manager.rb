require "./helpers"
require "./core/user_provider"

class UserManager
  def self.add(login, password, username, email)
    found_user = UserProvider.get(login)
    if found_user.nil?
      user_doc = {'_id' => login, 'Password' => Helpers.based64_md5(password),
                  'Name' => username, 'Email' => email, 'State' => 0}
      UserProvider.add(user_doc)
      true
    end
    false
  end

  def self.get(login)
    UserProvider.get(login)
  end

  def self.set_state(login, state)
    UserProvider.set_state(login, state)
  end

  def self.get_authenticated(cookie) # need more any_nil_or_empty? on objects
    if !cookie.nil?
      ticket = cookie.split(':')
      if ticket.size == 2
        login = ticket[0]
        cookie_token = ticket[1]
        user = UserProvider.get(login)
        if !user.nil? && cookie_token == user.password
          user
        else
          return nil
        end
      else
        return nil
      end
    else
      return nil
    end
  end
end

#  @username 		    = user.name
#  @state				    = user.state
#  @login				    = user.login
#  @currentRecordId  = user.currentRecordId