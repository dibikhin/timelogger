require "mongo"

class RecordProvider
  private
  def self.records
    return @records if @records
    @records = Mongo::Connection.from_uri(
        "mongodb://myusername:myuserpass@flame.mongohq.com:27019/Timelog").db("Timelog").collection("Records")
    @records
  end


  public
  def self.add(login, start_utc)
    records.insert({'UserId' => login, 'StartUtc' => start_utc})
  end

  def self.get(current_record_id)
    record_doc = records.find_one({'_id' => current_record_id})
    Record.new(record_doc)
  end

  def self.get_record_list(login, start_utc, end_utc)
    records.find({'UserId' => login, 'StartUtc' => {'$gte' => start_utc, '$lte' => end_utc}})
  end

  def self.set(record)
    records.update(
        {'_id' => record.id},
        {'$set' =>
             {'EndUtc' => record.endUtc,
              'TaskId' => record.taskId,
              'Description' => record.description,
              'IsFinished' => record.isFinished}})
  end

  def self.set_last_pause_start(current_record_id)
    records.update({'_id' => current_record_id}, {'$set' => {'LastPauseStartUtc' => Time.now.utc}})
  end

  def self.set_resume(current_record_id, last_pause_start_utc, total_paused_duration)
    records.update(
        {'_id' => current_record_id},
        {'$set' =>
             {'LastPauseStartUtc' => last_pause_start_utc,
              'TotalPausedDuration' => Time.at(total_paused_duration).utc.strftime('%H:%M:%S')}}) # 1612 -> 00:26:52
  end
end

#public void SetResume(ObjectId recordId, DateTime? lastPauseStartUtc, TimeSpan totalPausedDuration)
#{
#    _recordsCollection.Update(
#        Query.EQ("_id", recordId),
#        Update.Set("LastPauseStartUtc", lastPauseStartUtc)
#        .Set("TotalPausedDuration", totalPausedDuration.ToString()));
#// achtung! ToString() is necessary while lack of bson TimeSpan is present
#}