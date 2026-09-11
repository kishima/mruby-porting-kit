# SYMBOL 命令が出る入力を探す。Prism は式展開の無い :"..." を SymbolNode にするので LOADSYM になる。
# InterpolatedSymbolNode になるのは式展開があるときだけで、その場合は STRCAT を経て INTERN になる
def f
  a = :"abc"
  b = :"a b"
  c = %s{pct}
  d = :"aあ"
  e = :"ab
cd"
  g = :"a#{}b"
  h = :"#{"x"}"
  i = %I[x#{1} y]
  nil
end
