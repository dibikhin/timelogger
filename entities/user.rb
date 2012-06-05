class User
  attr_reader :login, :password, :name, :email, :state, :currentRecordId,
              :redmineTimeEntriesUrl, :redmineApiKey, :redmineDefaultActivityId,
              :utc_offset

  def initialize(doc)
    @login = doc['_id']
    @password = doc['Password']
    @name = doc["Name"]
    @email = doc["Email"]

    @state = doc['State']
    @currentRecordId = doc['CurrentRecordId']

    @redmineTimeEntriesUrl = doc["RedmineTimeEntriesUrl"]
    @redmineApiKey = doc["RedmineApiKey"]
    @redmineDefaultActivityId = doc["RedmineDefaultActivityId"]

    @utc_offset = doc['UtcOffset']
  end

  def is_redmine_configured?
    !Helpers.any_nil_or_empty?(@redmineApiKey,@redmineDefaultActivityId, @redmineTimeEntriesUrl)
  end
end