# LOADTRUE/LOADFALSE がリテラル以外から生成される場面
def f(x)
  x in Integer       # 結果として LOADTRUE / LOADFALSE
end
def g(x)
  x => Integer       # 不一致なら LOADFALSE + MATCHERR
  nil
end
def h(x)
  case x
  in Integer then 1  # else 無しの case/in も LOADFALSE + MATCHERR
  end
end
X ||= 1              # 定数が未定義（NameError）のとき EXCEPT + LOADFALSE で続行
