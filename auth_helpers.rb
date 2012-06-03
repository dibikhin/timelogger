require 'base64'
require 'digest'

class AuthHelpers
  def self.based64_md5(string)
    Base64.strict_encode64(Digest::MD5.digest(string))
  end

  def self.auth_ok?(user, login, password)
    user.login == login && user.password == based64_md5(password)
  end

  def self.get_ticket(login, password)
    login + ':' + based64_md5(password)
  end
end