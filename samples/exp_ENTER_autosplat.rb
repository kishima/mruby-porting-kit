def y1; yield [1, 2]; end
def y2; yield [1, 2], 3; end
def y3; yield 1; end
p y1 { |a, b| [a, b] }
p y1 { |a| a }
p y2 { |a, b| [a, b] }
p y3 { |a, b| [a, b] }
p [[1, 2], [3, 4]].map { |a, b| a + b }
l = lambda { |a, b| [a, b] }
begin
  p l.call([1, 2])
rescue ArgumentError => e
  p [:lambda, e.message]
end
pr = proc { |a, b| [a, b] }
p pr.call([1, 2])
p pr.call([1, 2], 3)
