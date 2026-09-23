# Proc.new と proc と lambda のフラグの違い（4.1.0-rc2）
def by_new;    Proc.new { |x| x }; end
def by_proc;   proc { |x| x }; end
def by_lambda; lambda { |x| x }; end
def by_block(&b); b; end
p by_new.lambda?, by_proc.lambda?, by_lambda.lambda?, by_block { }.lambda?
p by_new.call, by_new.call(1, 2)        # 引数は緩い
def m1; pr = Proc.new { return :from_proc }; pr.call; :after; end
def m2; pr = proc { return :from_proc }; pr.call; :after; end
def m3; pr = by_block { return :from_block }; pr.call; :after; end
p m1, m2, m3
def m4; pr = Proc.new { break :brk }; pr.call; :after; end
begin; p m4; rescue LocalJumpError => e; p e; end
def m5; pr = by_block { break :brk }; pr.call; :after; end
begin; p m5; rescue LocalJumpError => e; p e; end
def m6; pr = proc { break :brk }; pr.call; :after; end
begin; p m6; rescue LocalJumpError => e; p e; end
