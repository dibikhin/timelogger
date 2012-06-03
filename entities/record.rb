class Record
  attr_accessor :id, :startUtc, :endUtc, :taskId, :description,
                :isFinished, :lastPauseStartUtc, :totalPausedDuration

  def initialize(doc)
    @id = doc['_id']
    @userId = doc['UserId']
    @startUtc = doc['StartUtc']
    @endUtc = doc['EndUtc']
    @taskId = doc['TaskId']
    @description = doc['Description']
    @isFinished = doc['IsFinished']
    @lastPauseStartUtc = doc['LastPauseStartUtc']

    # '00:26:52.6284490' -> Wed May 23 00:26:52 +0400 2012 -> 1612
    total_paused_duration_str = doc['TotalPausedDuration']
    if !total_paused_duration_str.nil?
      total_paused_time = Time.parse(total_paused_duration_str)
      @totalPausedDuration = total_paused_time.hour * 60 + total_paused_time.min * 60 + total_paused_time.sec
    end
  end

  def duration
    if @startUtc.nil? || @endUtc.nil?
      @duration = nil
    elsif !@totalPausedDuration.nil?
      @duration = Time.at((@endUtc - @startUtc) - @totalPausedDuration).utc
    else
      @duration = Time.at(@endUtc - @startUtc).utc # 1356 -> Thu Jan 01 00:22:36 UTC 1970
    end
  end
end