module TestModule
  Const = 1
  class MyClass
  end
end

TestModule::Const = 2
p TestModule::Const

obj = TestModule::MyClass.new

