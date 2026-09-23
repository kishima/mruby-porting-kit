# B-4: スケジューラ駆動 GC で、停止がどこへ移るか。
# mruby-task と MRB_GC_PROFILE の両方が要る。
#   mruby gc_scheduler.rb <on|off> [frames] [alloc_per_frame] [live]
#
# 仮説: GC.scheduler_driven = true にすると、割り当て経路の停止
# （prof_sync_*）がスケジューラのアイドル時間の停止（prof_step_*）に移る。
# 仮説が偽なら違う結果になる入力: 同じ仕事を off でも回す。off でも
# prof_step が出るなら「移る」ではないし、on でも prof_sync が減らない
# なら効いていない。
#
# 1 フレームあたりの割り当て数の既定 2000 は、既定の 1 ステップの仕事量
# （GC_STEP_SIZE/100 * step_ratio = 10*200 = 2000、src/gc.c:1763）と
# 同じ数にしてある。1 フレームで 1 ステップぶんのゴミが出る、という
# 分かりやすい比になる。
mode = ARGV[0] || "off"
frames = (ARGV[1] || "200").to_i
per = (ARGV[2] || "2000").to_i
live = (ARGV[3] || "5000").to_i

keep = Array.new(live) { |i| "live#{i}" }
GC.scheduler_driven = true if mode == "on"
GC.start
GC.reset_stat

Task.new(name: "worker") do
  frames.times do |f|
    per.times { |i| keep[i % live] = "g#{f}_#{i}" }
    sleep 0.005   # アイドル時間を作る。ここでスケジューラが GC を刻む
  end
end

t0 = Task.stat[:tick]
Task.run
t1 = Task.stat[:tick]

s = GC.stat
p [:mode, mode, :scheduler_driven, GC.scheduler_driven,
   :generational, GC.generational_mode, :debt_limit, GC.debt_limit]
p [:sync, {count: s[:prof_sync_count], total_us: s[:prof_sync_total_us],
           max_us: s[:prof_sync_max_us]}]
p [:sync_hist, s[:prof_sync_hist]]
p [:step, {count: s[:prof_step_count], total_us: s[:prof_step_total_us],
           max_us: s[:prof_step_max_us]}]
p [:step_hist, s[:prof_step_hist]]
p [:jitter, {count: s[:prof_step_jitter_count],
             total_us: s[:prof_step_jitter_total_us],
             max_us: s[:prof_step_jitter_max_us]}]
p [:jitter_hist, s[:prof_step_jitter_hist]]
p [:work, {mark: s[:prof_mark_work_total],
           sweep: s[:prof_sweep_work_total],
           final_mark_max_us: s[:prof_final_mark_max_us],
           emergency: s[:prof_emergency_count]}]
p [:gc, {total: s[:total], minor: s[:minor], major: s[:major],
         live: s[:live], debt: s[:debt]}]
p [:slots, ObjectSpace.count_objects[:TOTAL]]
p [:ticks, t1 - t0]   # スケジューラのティック数。経過時間の目安
