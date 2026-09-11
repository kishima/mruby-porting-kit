def f
  out = 1
  pr = Proc.new { out += 1 }
  pr.call
  out
end
