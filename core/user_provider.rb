require "mongo"

class UserProvider
  private
    def self.users
      return @users if @users
      @users = Mongo::Connection.from_uri(
          "mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog").db("Timelog").collection("Users")
      @users
    end


  public
  def self.add(user_doc)
    users.insert(user_doc)
  end

  def self.get(login) #  need more any_nil_or_empty
    user_doc = users.find_one('_id' => login)
    user_doc.nil? ? nil : User.new(user_doc)
  end

  def self.set_state(login, state)
    users.update({'_id' => login}, {'$set' => {'State' => state}})
  end

  def self.set_current_record_id(login, current_record_id)
    users.update({'_id' => login}, {'$set' => {'CurrentRecordId' => current_record_id}})
  end
end