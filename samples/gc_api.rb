p GC.singleton_methods.sort
p GC.stat.keys
p defined?(ObjectSpace)
p ObjectSpace.count_objects.keys
h = ObjectSpace.count_objects
p [h[:TOTAL], h[:FREE], h[:TOTAL] % 1024]
