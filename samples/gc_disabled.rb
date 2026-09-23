a = Array.new(3000) { |i| "s#{i}" }
a = nil
p [:before, GC.stat[:live]]
p [:disable_returns, GC.disable]
GC.start
p [:after_start_while_disabled, GC.stat[:live]]
p [:enable_returns, GC.enable]
GC.start
p [:after_start_enabled, GC.stat[:live]]

# generational_mode change while disabled
GC.disable
begin
  GC.generational_mode = false
rescue => e
  p [:gen_change_while_disabled, e.class, e.message]
end
GC.enable

# ObjectSpace iteration: GC.start inside the block
n = 0
ObjectSpace.each_object do |o|
  if n == 0
    GC.start
    p [:live_inside_iteration, GC.stat[:live]]
  end
  n += 1
end
p [:iterated, n]
