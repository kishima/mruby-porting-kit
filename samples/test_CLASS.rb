class Base
end
module Mod
end
class Mod::Sub < Base
  def m
  end
end
class ::Top
end
