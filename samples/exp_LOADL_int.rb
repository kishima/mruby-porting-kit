# LOADL: int32 を超える整数リテラルが、ビルド設定（MRB_INT32 / bigint の有無）で
# どう扱われるかを見る。値ごとに別の irep にして RangeError を個別に受ける
def try
  yield
rescue => e
  p [e.class, e.message]
end
try { p 2147483647 }
try { p 2147483648 }
try { p(-2147483649) }
try { p 9223372036854775807 }
try { p 9223372036854775808 }
try { p(-9223372036854775809) }
