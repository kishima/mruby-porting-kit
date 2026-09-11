def m
  proc { yield }
end
pr = m { 42 }
p pr.call
def m2
  proc { |x| yield x }
end
begin
  p m2.call(7)
rescue LocalJumpError => e
  p [:m2, e.message]
end
def foo; __method__; end
alias bar foo
p [foo, bar]
