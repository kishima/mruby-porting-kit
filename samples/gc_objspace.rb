def co
  h = ObjectSpace.count_objects
  [h[:TOTAL], h[:FREE]]
end
p [:start, GC.stat[:live], co]
a = Array.new(5000) { |i| "s#{i}" }
p [:alloc, GC.stat[:live], co]
a = nil
n = ObjectSpace.each_object { |o| }
p [:each_object_returned, n]
p [:after_each, GC.stat[:live], co]
GC.start
p [:after_start, GC.stat[:live], co]
