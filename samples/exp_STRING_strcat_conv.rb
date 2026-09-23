# STRCAT（mrb_str_concat）が非文字列をどう文字列にするか（4.1.0-rc2）
class Integer
  def to_s(*); "INT"; end
end
class Symbol
  def to_s; "SYM"; end
end
class Foo
  def to_s; "foo!"; end
end
class Bar; end
p "#{1}"         # Integer は to_s を呼ばず直接変換するはず
p "#{:a}"        # Symbol も
p "#{nil}"       # nil は to_s 経由
p "#{Foo.new}"   # ユーザ定義 to_s
p "#{Foo}"       # クラスは mrb_mod_to_s
s = "#{Bar.new}"
p s[0, 6]        # 既定の to_s
