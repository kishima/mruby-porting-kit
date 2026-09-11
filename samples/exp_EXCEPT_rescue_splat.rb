ERRS = [ArgumentError, TypeError]
def f(e)
  raise e, "x"
rescue *ERRS => ex
  "splat: #{ex.class}"
rescue ZeroDivisionError, *[RuntimeError]
  "mixed"
end
p f(TypeError)
p f(RuntimeError)
begin
  f(NameError)
rescue NameError => e
  p [:outer, e.class]
end
