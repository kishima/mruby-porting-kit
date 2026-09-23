# B-2: ヒープページの増え方と返り方を ObjectSpace.count_objects で見る。
# count_objects は mrb_objspace_each_objects 経由なので、数える前に
# 必ず mrb_full_gc が走る（src/gc.c:2366）。つまり下の TOTAL は
# 「フル GC の直後のヒープの箱の総数」である。
def tot
  o = ObjectSpace.count_objects
  [o[:TOTAL], o[:FREE]]
end

p [:start, tot]
p [:start_total_mod_1024, ObjectSpace.count_objects[:TOTAL] % 1024]

# 箱を増やしていって、TOTAL が変わった瞬間だけ記録する。
# 増分が 1024 の倍数なら、ページ単位（MRB_HEAP_PAGE_SIZE）で増えている。
keep = []
prev = ObjectSpace.count_objects[:TOTAL]
steps = []
while keep.size < 30000
  500.times { keep << Object.new }
  t = ObjectSpace.count_objects[:TOTAL]
  if t != prev
    steps << [keep.size, t, t - prev]
    prev = t
  end
end
steps.each { |s| p s }
p [:increments_mod_1024, steps.map { |s| s[2] % 1024 }.uniq]

p [:live_30000, tot]
keep = nil
p [:dropped, tot]      # count_objects 自体がフル GC をしている
GC.start
p [:after_start, tot]
GC.start
p [:after_start2, tot]
