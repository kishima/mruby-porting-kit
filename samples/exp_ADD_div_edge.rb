# DIV の境界（4.1.0-rc2, MRB_INT64, MRB_USE_BIGINT）
p 7 / 2, -7 / 2, 7 / -2, -7 / -2       # 切り捨て方向（負の無限大方向）
x = -9223372036854775808
p x / -1, (x / -1).class               # INT_MIN / -1
p 1.0 / 0, -1.0 / 0, 0.0 / 0           # Float の 0 除算は例外にならない
p 1 / 0.0
begin
  1 / 0
rescue ZeroDivisionError => e
  p e
end
