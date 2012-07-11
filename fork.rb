# 80 port needs privileges, in this case run it as: rvmsudo ruby fork.rb

pid = Process.fork
if pid.nil? then
  # in child
  exec 'ruby timelogger.rb -p 80'
else
  # in parent
  Process.detach(pid)
end
