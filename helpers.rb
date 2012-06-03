class Helpers
  def self.any_nil_or_empty?(*params)
    params.any? {|param| nil_or_empty?(param)}
  end


  private
  def self.nil_or_empty?(param)
    param.nil? || param.empty?
  end
end