# B-3: 世代別モードで、マイナー GC とメジャー GC がそれぞれ何回走るか。
# :total / :minor / :major は MRB_GC_STATS 付きのビルドにしか無い。
#   mruby gc_generational.rb <生存させる数> <1=世代別 0=非世代別>
#                           [interval_ratio]
#
# 仮説: 世代別モードならサイクルの大半はマイナー GC になる。
# 仮説が偽なら違う結果になる入力を 2 方向に用意する。
#  (1) 生存数を変える。incremental_gc_run（src/gc.c:1828-1840）は
#      メジャー GC の後のしきい値を live_after_mark/100*120 で計算し、
#      それが MAJOR_GC_TOOMANY（10000）以上ならしきい値を更新せず
#      その場で mrb_full_gc を呼ぶ。生存数が 10000/1.2 = 8333 あたりの
#      境界をまたぐ入力を並べる
#  (2) interval_ratio を変える。サイクル終わりのクレジットは
#      live_after_mark*(interval_ratio/100) - live_after_mark なので、
#      既定の 200 では「生存数と同じ数」を新たに作るまで次のサイクルが
#      始まらない。これが空き箱の数より大きいと、負債ではなく
#      「空きページが無くなったこと」で GC が起きる
#      （mrb_obj_alloc_core、src/gc.c:801-822 の mrb_full_gc）。
#      110 にするとクレジットが生存数の 10% になり、負債で始まるようになる
live = (ARGV[0] || "1000").to_i
gen = (ARGV[1] || "1") == "1"
ratio = (ARGV[2] || "200").to_i

GC.generational_mode = gen
GC.interval_ratio = ratio
GC.start
a = Array.new(live) { |i| "s#{i}" }
GC.start
# count_objects は数える前にフル GC をする（src/gc.c:2366）ので、
# ここで取ると b0 のカウンタにその 1 回が入る。
os = ObjectSpace.count_objects
b0 = GC.stat

# 生存数を一定に保ったままゴミを出し続ける。
# ついでに負債の最大値を見る。GC が負債で駆動されているなら、負債は
# 0 を超えた直後に GC が進んで下がるので、最大値は 0 の近くになる。
# ずっと負のままなら、GC を起こしているのは負債ではない。
# 見る間隔の 500 は、この実験で最小のクレジット（GC_STEP_SIZE=1024）
# より細かく、1 サイクルに 2 回以上は見られる値。
dmax = -(1 << 40)
(live * 20).times do |i|
  a[i % live] = "t#{i}"
  if i % 500 == 0
    d = GC.stat[:debt]
    dmax = d if d > dmax
  end
end

b1 = GC.stat
p [:live_arg, live, :generational, GC.generational_mode,
   :interval_ratio, GC.interval_ratio]
# credit は「次のサイクルが始まるまでに作れる数」。負債の符号を返した値。
# free は今空いている箱の数。credit > free なら、負債が 0 になる前に
# 空きページが尽きる。
p [:before, {total: b0[:total], minor: b0[:minor], major: b0[:major],
             live: b0[:live], credit: -b0[:debt],
             slots: os[:TOTAL], free: os[:FREE]}]
p [:after, {total: b1[:total], minor: b1[:minor], major: b1[:major],
            live: b1[:live]}]
p [:delta, {total: b1[:total] - b0[:total],
            minor: b1[:minor] - b0[:minor],
            major: b1[:major] - b0[:major],
            debt_max: dmax}]
