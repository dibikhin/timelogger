require 'json/ext'
require 'rest_client'

require "./core/record_provider"
require "./core/user_provider"
require './helpers'

class RecordManager
  def self.get_today_records(login)
    time = Time.now # Wed May 23 00:00:00 +0400 2012 -> Tue May 22 20:00:00 UTC 2012
    RecordProvider.get_record_list(login, Time.local(time.year, time.month, time.day).utc, Time.now.utc)
  end

  def self.start_new_record(login)
    new_record_id = RecordProvider.add(login, Time.now.utc)
    UserProvider.set_current_record_id(login, new_record_id)
  end

  def self.end_record(user, task_id = nil, description = nil)
    record = RecordProvider.get(user.currentRecordId)
    record.taskId = task_id
    record.description = description
    record.endUtc = Time.now.utc
    record.isFinished = true # TODO remove, === !endUtc.nil?

    RecordProvider.set(record)
    UserProvider.set_current_record_id(user.login, nil)

    save_to_redmine(user, record) # todo return SaveToRedmine(login, record);
  end

  def self.pause(current_record_id)
    RecordProvider.set_last_pause_start(current_record_id)
  end

  def self.resume(current_record_id)
    record = RecordProvider.get(current_record_id)
    last_paused_duration = lambda { Time.now.utc - record.lastPauseStartUtc }

    if record.totalPausedDuration.nil?
      record.totalPausedDuration = last_paused_duration.call
    else
      record.totalPausedDuration += last_paused_duration.call
    end
    record.lastPauseStartUtc = nil

    RecordProvider.set_resume(current_record_id, record.lastPauseStartUtc, record.totalPausedDuration)
  end


  private
  def self.save_to_redmine(user, record)
    #if (user.IsRedmineConfigured()
    unless Helpers.any_nil_or_empty?(record.description, record.taskId)
      # RestClient::ResourceNotFound when issue not found
      # Apache Web Server Unavailable
      # 503 - Redmine Service Temporarily Unavailable
      # 406 - Redmine URL incorrect
      # 401 - Redmine unauthorized
      # Redmine ignores errors in ActivityId and ProjectId
      RestClient.post(
          user.redmineTimeEntriesUrl,
          create_time_entry_json(record, user.redmineDefaultActivityId),
          {:content_type => :json, 'X-Redmine-API-Key' => user.redmineApiKey})
    end
  end

  SECS_IN_ONE_HOUR = 3600.0

  def self.create_time_entry_json(record, default_activity_id)
    JSON.generate(
        {:time_entry =>
             {:issue_id => record.taskId,
              :hours => record.duration.to_i / SECS_IN_ONE_HOUR, # Thu Jan 01 00:22:36 UTC 1970 -> 0.376666666666667
              :activity_id => default_activity_id,
              :comments => record.description}})
  end
end