# ターゲットクラスが無い状況で def / alias / undef / class をすると何が起きるか
def try(label)
  yield
  puts "#{label}: ok"
rescue => e
  puts "#{label}: #{e.class}: #{e.message}"
end

try("eval def")            { eval("def a; end") }
try("Fiber def")           { Fiber.new { def b; end }.resume }
try("Object#instance_eval def") { Object.new.instance_eval { def c; end } }
try("nil.instance_eval def")    { nil.instance_eval { def d; end } }
try("1.instance_eval def")      { 1.instance_eval { def e; end } }
try("1.instance_eval alias")    { 1.instance_eval { alias f e } }
try("1.instance_eval undef")    { 1.instance_eval { undef to_s } }
try("1.instance_eval class")    { 1.instance_eval { class Zzz; end }; p Zzz }
try(":s.instance_eval def")     { :s.instance_eval { def g; end } }
try("1.5.instance_exec def")    { 1.5.instance_exec { def h; end } }
try("1.instance_eval def (string)") { 1.instance_eval("def i; end") }
