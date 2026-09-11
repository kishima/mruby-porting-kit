# GETCV/SETCV: 特異クラスの本体や特異メソッドの中の @@x が、どのクラスの変数になるか
class A
  @@x = 1
  class << self
    @@x = 2
    def sx; @@x; end
    def sy; @@y = 3; end
  end
  def ix; @@x; end
end
p A.sx                              # 2
p A.new.ix                          # 2（特異クラス本体の代入が A の @@x を書き換えた）
p A.sy                              # 3
p A.class_variables                 # [:@@x, :@@y]
p A.singleton_class.class_variables # []
