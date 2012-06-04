class Helpers
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
