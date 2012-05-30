require "./core/record_provider"
require "./core/user_provider"

class RecordManager
  def self.get_today_records(login)
    time = Time.now		# Wed May 23 00:00:00 +0400 2012 -> Tue May 22 20:00:00 UTC 2012
    RecordProvider.get_record_list(login, Time.local(time.year, time.month, time.day).utc, Time.now.utc)
  end

  def self.start_new_record(login)
    new_record_id = RecordProvider.add(login, Time.now.utc)
    UserProvider.set_current_record_id(login, new_record_id)
  end

  def self.end_record(login, current_record_id)
    record = RecordProvider.get(current_record_id)
    # record.taskId =  task_id
    # record.description = description
    record.endUtc = Time.now.utc
    record.isFinished = true # TODO remove, === !endUtc.nil?
    RecordProvider.set(record)

    ## return SaveToRedmine(login, record);
  end
end