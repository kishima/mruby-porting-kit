def f
  a = ->(x) { x }
  b = lambda { |x| x }
  c = Proc.new { |x| x }
  [1].each { |x| x }
  nil
end
