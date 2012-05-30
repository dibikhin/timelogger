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
end

#public void Set(Record record)
#{
#    _recordsCollection.Update(
#        Query.EQ("_id", record.Id),
#        Update.Set("EndUtc", record.EndUtc.Value).Set("TaskId", record.TaskId)
#        .Set("Description", record.Description).Set("IsFinished", record.IsFinished));
#}