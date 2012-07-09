class Helpers
  MONGOHQ_URL = ENV['MONGOHQ_URL']

  def self.user_date_start(user_utc_offset)
    # 2012-06-07 06:00:00 +0100 ->
    # 2012-06-07 09:00:00 +0400 ->
    # 2012-06-07 00:00:00 +0400

    server_now = Time.now
    user_now = server_now.localtime(user_utc_offset)
    user_time_seconds = (user_now.hour * 60 * 60 + user_now.min * 60 + user_now.sec)
    user_now - user_time_seconds
  end

  def self.any_nil_or_empty?(*params)
    params.any? { |param| nil_or_empty?(param) }
  end


  private
  def self.nil_or_empty?(param)
    param.nil? || param.empty?
  end
end


class Time
  def nice_strftime
    if self.nil?
      return ''
    end

    if self.hour == 0
      if self.min == 0
        self.sec.to_s + ' sec' # 45 sec
      else
        self.min.to_s + ' min' # 20 min
      end
    else
      self.hour.to_s + ' h ' + self.min.to_s + ' min' # 1 h 24 min
    end
  end
end

class Fixnum
  def in?(range)
    range === self
  end
end