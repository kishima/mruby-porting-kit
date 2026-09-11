

begin
  a=1
  raise
rescue => e
  b=2
ensure
  c=3
  p a
  p b
end

puts "--"
p a
p b
p c



