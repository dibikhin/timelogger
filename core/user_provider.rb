require "mongo"

class UserProvider
  def self.add(user_doc)
    users.insert(user_doc)
  end

  def self.get(login)
    user_doc = users.find_one('_id' => login)
    unless user_doc.nil?
      User.new(user_doc)
    end
  end

  def self.set_state(login, state)
    users.update({'_id' => login}, {'$set' => {'State' => state}})
  end

  def self.set_current_record_id(login, current_record_id)
    users.update({'_id' => login}, {'$set' => {'CurrentRecordId' => current_record_id}})
  end

  def self.set_redmine_settings(login, time_entries_url, api_key, default_activity_id)
    users.update(
    {'_id' => login},
    {'$set' => {
    'RedmineTimeEntriesUrl' => time_entries_url,
    'RedmineApiKey' => api_key,
    'RedmineDefaultActivityId' => default_activity_id}})
  end


  private
  def self.users
    return @users if @users
    @users = Mongo::Connection.from_uri(Helpers::MONGOHQ_URL).db("Timelog").collection("Users")
    @users
  end
end