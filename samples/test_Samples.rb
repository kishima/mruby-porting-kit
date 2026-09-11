#JMPNIL

Object.new&.__id__

#ARGARY,SUPER
class Test
	def m
		super
	end
end

#ARGCAT
a=*"a"

#AREF,APOST
->((x,y),z=0){}

#INTERN
b = %I(abc #{2+3} def \(g)

#STRCAT
a="a"
"#{a}"

#BLKPUSH
def method(*v)
end
def m(a,*b)
	yield
end
arg=[1,2,3]
method m(*arg){1},1

#SENDV
def arg2ary(*args)
	args
end
method [0]*127,arg2ary(
	0,0,0,0
)

#RETURN_BLK
class Test
	def try
		yield
	end
end

v=Test.new

lambda do 
 v.try do
	return
 end
end.call

#OCLASS
class ::A
end

#HASHADD
# make long hash
h ={
	:v001 => "a",
	:v002 => "a"
}