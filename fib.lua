local fib = {}
local mt ={}
local g = rawget

fib.cache = {[0] = 0, [1] = 1} --Cache helps to prevent unnecessary recalculations

function fib.expend(n) --expend the cache to the n-th Fibonacci number and return the number
  local prev = fib.cache[n-1] or fib.expend(n-1)
  fib.cache[n] = prev + fib.cache[n-2]
  return fib.cache[n]
end
 
function mt.__index(t, k)
  return g(t, 'cache')[k] or g(t, k) or g(t, 'expend')(k)
end

return setmetatable(fib, mt)
 