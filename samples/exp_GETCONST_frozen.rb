# SETCONST/SETMCNST: frozen なクラスへの定数定義は FrozenError
class A; end
A.freeze
begin
  class A; X = 1; end   # SETCONST（クラス本体）
rescue => e
  p e.class, e.message
end
begin
  A::Y = 2              # SETMCNST
rescue => e
  p e.class, e.message
end
begin
  Object.freeze
  Z = 3                 # SETCONST（トップレベル、対象は Object）
rescue => e
  p e.class, e.message
end
