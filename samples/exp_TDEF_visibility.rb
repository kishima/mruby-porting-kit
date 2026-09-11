# MRB_METHOD_VDEFAULT_FL がどの可視性に解決されるか
class A
  def pub; end
  private
  def pri; end
  def self.cm; end          # 特異メソッドは private 宣言下でも public
  def initialize; end       # 常に private
  def respond_to_missing?(*); false; end  # 常に private
  public
  def pub2; end
  protected
  def pro; end
end
p A.public_instance_methods(false).sort
p A.private_instance_methods(false).sort
p A.protected_instance_methods(false).sort
p A.singleton_class.public_instance_methods(false)

def top_def; end            # トップレベルの def
p Object.private_instance_methods(false).include?(:top_def)
p Object.public_instance_methods(false).include?(:top_def)

module M
  module_function
  def mf; :mf; end
end
p M.private_instance_methods(false), M.singleton_methods, M.mf

class B; end
B.class_eval do
  private
  def in_block; end         # ブロック内の private（環境側の可視性）
end
p B.private_instance_methods(false)

class C
  private
  def a; end
  def b; end
end
class C                     # 再オープンすると可視性はリセットされる
  def c; end
end
p C.private_instance_methods(false).sort, C.public_instance_methods(false)
