def f(obj, arr, h)
  obj.push(*arr)
  obj.push(1, *arr, 2)
  obj.m(a: 1, b: 2)
  obj.m(**h)
  obj.m(1, k: 2)
end
