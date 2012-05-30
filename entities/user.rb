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