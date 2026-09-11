# SETMCNST: R[a+1] がクラス・モジュールでないときの挙動。構文上は通り、実行時に TypeError
begin
  x = 3
  x::X = 1
rescue => e
  p e.class, e.message
end
begin
  3::Y = 1
rescue => e
  p e.class, e.message
end
