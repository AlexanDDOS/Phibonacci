local bt = {}

function bt.__index(t, k)
  return rawget(t, K) or bt[k]
end

function bt.new(x, y, w, h, label)
  assert(type(label) == 'string', "label must be a string")
  local t = {
    x = x, y = y,
    w = w, h = h,
    label = label
  }
  return setmetatable(t, bt)
end

function bt.drawBg(t)
  love.graphics.rectangle('fill', t.x, t.y, t.w, t.h)
end

function bt.drawLabel(t, l)
  l = l or t.label
  
  if l then
    love.graphics.printf(l, t.x, t.y, t.w, 'center')
  end
end

function bt:draw(bgc, fc)
  fc = fc or {love.graphics.getColor()}
  
  love.graphics.setColor(bgc)
  bt.drawBg(self)
  love.graphics.setColor(fc)
  bt.drawLabel(self)
end

function bt.hasPoint(t, x, y)
  local bx, by = t.x, t.y
  return not (x < bx or y < by or x > bx + t.w or y > by + t.h) 
end

function bt.hovered(t)
  local x, y = love.mouse.getPosition()
  return bt.hasPoint(t, x, y)
end

function bt.clicked(t)
  if bt.hovered(t) then
    return love.mouse.isDown(1)
  end
end

return bt