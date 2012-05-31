require "./core/record_provider"
require "./core/user_provider"

class RecordManager
  def self.get_today_records(login)
    time = Time.now # Wed May 23 00:00:00 +0400 2012 -> Tue May 22 20:00:00 UTC 2012
    RecordProvider.get_record_list(login, Time.local(time.year, time.month, time.day).utc, Time.now.utc)
  end

  def self.start_new_record(login)
    new_record_id = RecordProvider.add(login, Time.now.utc)
    UserProvider.set_current_record_id(login, new_record_id)
  end

  def self.end_record(login, current_record_id, task_id = nil, description = nil)
    record = RecordProvider.get(current_record_id)
    record.taskId = task_id
    record.description = description
    record.endUtc = Time.now.utc
    record.isFinished = true # TODO remove, === !endUtc.nil?
    RecordProvider.set(record)

    ## return SaveToRedmine(login, record);
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
end