--[[
There're all the code of game logic and field drawing. 
I suspect my code is bad somewhere, especially in the animation sections. 
So, can't you help me make it better, if it is?
]]

local field = {w = 4, h = 4}
local gph = love.graphics

field.tiles = {} --[[Tiles have values, which are equal to order numbers of the Fibonacci numbers, not the Fibonacci numbers by themselves. 
Empty tiles have `false`.]]
field.oldTiles = {} --Old tiles
field.occupiedTiles = 0

field.animations = {} --[[ [non-true value] = non-animation, [0-1 number] = appearance, 
-1 = hide, {x, y, dx, dy, v, completeness, app} = moving]]
field.animated = nil

for i = 1, field.w * field.h do
  field.tiles[i] = field.tiles[i] or false
  field.oldTiles[i] = field.tiles[i]
end

local c = field.tiles
local sz = field.size and field.size() or 16 --field size

local function xyToN(x, y)
  return field.w * y + x + 1
end

function field.clear()
  c = {}
  field.tiles, field.oldTiles = c, {}
  sz = field.size()
  field.occupiedTiles = 0
  field.firstTurn = true
end

function field.get(x, y)
  return field.tiles[xyToN(x, y)]
end

function field.set(x, y, v)
  field.tiles[xyToN(x, y)] = v
end

function field.backupTiles()
  for k, v in pairs(c) do
    field.oldTiles[k] = v
  end
end

function field.size()
  return field.w * field.h
end

function field.undo()
  if not (field.animated or field.firstTurn or #field.oldTiles == 0) then
    c = field.oldTiles
    field.tiles, field.oldTiles = c, {}
  end
end

function field.addAnim(sx, sy, fx, fy, ov)
  if sx == nil then
    return
  elseif fx == nil then --Appearing tile
    if not field.animations[sx] then
     field.animations[sx] = 0
    elseif type(field.animations[sx]) == 'table' then
      field.animations[sx][7] = true
    end
    return 0
  elseif sx == fx and sy == fy then
    return
  end
  
  for k, v in pairs(field.animations) do
    local tp = type(v):sub(1, 1)
    if tp == 't' then -- type(v) == 'table'
      local vfx, vfy = v[1]+v[3], v[2]+v[4]
      
      if vfx == sx and vfy == sy then
        v[3], v[4] = fx - v[1], fy - v[2]
        if v[8] and field.animations[v[8]] == -1 then
          field.animations[v[8]] = nil
        end
        return v
      end
    end
  end
  
  local anim = {sx, sy, fx-sx, fy-sy, ov, 0}
  local d = math.max(math.abs(anim[3]), math.abs(anim[4]))
  field.animations[xyToN(sx, sy)] = anim
  return anim
end

function field.updAnim(dt)
  local anim = field.animations
  local n = 0
  
  if field.animated then
    if field.animated < 0.25 then
      field.animated = field.animated + dt
    else
      field.animated = nil
      field.animations = {}
    end
  end
  
  local faddingtiles = {}
  
  for k, v in pairs(anim) do
    local tp = type(v):sub(1,1)
    if tp == 't' then -- type(v) == 'table'
      local d = dt * 4 * math.max(math.abs(v[3]), math.abs(v[4]))
      local c = v[6] + d
      local kf = v[8] or xyToN(v[1]+v[3], v[2]+v[4])
      v[8] = kf
      
      if c >= 1 then
        anim[kf] = nil
        anim[k] = nil
      else
        v[6] = c
        if not anim[kf] then
          anim[kf] = -0.25
        end
        n = n + 1
      end
    else
      if v > 1 then
        v = nil
      else
        v = v + dt * 4
        n = n + 1
      end
      anim[k] = v
    end
  end
  
end


function field.check(a, b) --Check if 2 tiles can ber blended or switched
  if not a or not b then
    return 2 --Switchable tiles
  elseif math.abs(a - b) == 1 or a == 2 and b == 2 then
    return 1 --Blendable tiles
  end
  return 0
end

function field.randomTile(moved)
  local s = sz
  if moved == false or gameOver and field.occupiedTiles >= s then
    field.animated = nil
    return
  end
  
  local i
  repeat
    i = love.math.random(s)
  until not c[i]
  
  local n = love.math.random(0, 3)
  if n < 2 then
    n = 2
  end
  
  c[i] = n
  field.occupiedTiles = field.occupiedTiles + 1
  field.addAnim(i)
  field.animated = 0
  
  if field.occupiedTiles >= s then
    gameOver = true
  end
  
  if gameOver then
    local w, h = field.w, field.h
    for x = 0, w-1 do
      for y = 0, h-1 do
        if x > 0 and field.check(c[i - 1], n) > 0 then
          gameOver = false
          break
        elseif x < w-1 and field.check(c[i + 1], n) > 0 then
          gameOver = false
          break
        elseif y > 0 and field.check(c[i - w], n) > 0 then
          gameOver = false
          break
        elseif y < h-1 and field.check(c[i + w], n) > 0 then
          gameOver = false
          break
        end
      end
    end
  end
end


function field.getTileColor(value)
  if not value then
    return 0, 0, 0, 0
  end
  
  local r,g,b = 0,0,0
  value = (value-1) % 25
  
  if value < 15 then
    value = 0.1 * (value - 5)
    b = 1 - math.abs(value)
    g = value
  elseif value < 20 then
    value = 0.2 * (value - 12)
    g = 1 - value + 0.25
    r = value + 0.25
  elseif value < 25 then
    value = 0.1 * (value - 20)
    r = 0.75 - value
    g = 0.5 - value * 2
    b = value
  end
  
  return r, g, b, 1
end

function field.moveTile(x, y, dx, dy)
  local sx, sy = x, y --Start x and y
  
  local i, d = xyToN(x, y), xyToN(dx, dy) - 1 --Curent tile index, index step
  local n = i + d --Next tile index
  local w, h = field.w - 1, field.h - 1
  
  if not c[i] then
      return
  end
  
  while true do
    local nx, ny = x + dx, y + dy
    local ci, cn = c[i], c[n]
    local checkRes = field.check(ci, cn)
    
    if not ci then
      return
    end
    
    if (nx < 0 or ny < 0 or nx > w or ny > h) then
      return true, ci, x, y, sx, sy
    end
    
    if checkRes == 2 then
      c[i], c[n] = false, ci
    elseif checkRes == 1 then
      local sum = math.max(ci, cn) + 1
      c[n] = sum
      c[i] = false
      field.occupiedTiles = field.occupiedTiles - 1
      
      score = score + fib[sum]
    else
      local moved = not(x == sx and y == sy)
      return moved, ci, x, y, sx, sy
    end
    
    x, y = nx, ny
    i, n = i + d, n + d
  end
end

function field.move(dir)
  
  if gameOver or field.animated then
    return
  end
  
  field.firstTurn = false
  
  local dx, dy = 0, 0
  local w, h = field.w, field.h
  local moved, ov, fx, fy, sx, sy = false
  
  field.backupTiles()
  
  if dir % 2 == 0 then
    dx = 1 - dir
    if dx > 0 then
      for ix = field.w - 2, 0, -1 do
        for iy = 0, field.h - 1 do
          local m
          m, ov, fx, fy, sx, sy = field.moveTile(ix, iy, 1, 0)
          moved = m or moved
          field.addAnim(sx, sy, fx, fy, ov)
        end
      end
    else
      for ix = 1, field.w - 1 do
        for iy = 0, field.h - 1 do
          local m
          m, ov, fx, fy, sx, sy = field.moveTile(ix, iy, -1, 0)
          moved = m or moved
          field.addAnim(sx, sy, fx, fy, ov)
        end
      end
    end
  else
    dy = dir - 2
    if dy > 0 then
      for iy = field.h - 2, 0, -1 do
        for ix = 0, field.w - 1 do
          local m
          m, ov, fx, fy, sx, sy = field.moveTile(ix, iy, 0, 1)
          moved = m or moved
          field.addAnim(sx, sy, fx, fy, ov)
        end
      end
    else
      for iy = 1, field.h - 1 do
        for ix = 0, field.w - 1 do
          local m
          m, ov, fx, fy, sx, sy = field.moveTile(ix, iy, 0, -1)
          moved = m or moved
          field.addAnim(sx, sy, fx, fy, ov)
        end
      end
    end
  end
  field.randomTile(moved)
end

function field.drawCell(num,size, a)
  local r,g,b = field.getTileColor(num)
  
  gph.setColor(r, g, b, a)
  gph.rectangle('fill', 0, 0, size, size)
  num = tostring(fib[num])

  gph.setColor(1, 1, 1, a)
  local fId = math.min(#num, 8)
  local font, fsize = fonts.latoB[fId], fonts.latoB.sizes[math.min(#num, 8)]
  gph.setFont(font)
  
  gph.printf(num, 0, fsize * (-0.125 + 0.5 * (fId-1)), size, 'center')
end

function field.draw(size, margin)
  local tileOffset = size + margin
  local w, h = field.w-1, field.h-1
  
  --Draw base grid
  for y = 0, h do
    for x = 0, w do
      gph.setColor(0.75, 0.75, 0.75, 1)
      gph.rectangle('fill', x * tileOffset, y * tileOffset, size, size)
    end
  end
  
  --Draw occupied grid tiles
  for y = 0, field.h-1 do
    local i = y * field.w
    
    for x = 0,field.w-1 do
      i = i + 1
      local num, anim = field.tiles[i], field.animations[i]
      local tx, ty = x, y
      local fx, fy
      local na = 1
      
      
      if anim and field.animated then
        if type(anim):sub(1, 1) == 't' then --type(anim) == 'table'
          tx, ty = anim[1] + anim[3] * anim[6], anim[2] + anim[4] * anim[6]
          if anim[7] then
            gph.push()
            gph.translate(tx * tileOffset, ty * tileOffset)
            field.drawCell(num, size, anim[6])
            gph.pop()
          end
          num = anim[5]
        else
          na = anim
        end
      end
      
      local r,g,b,a = field.getTileColor(num)
      a = a == 0 and 0 or na
      
      if num then
        gph.push()
        gph.translate(tx * tileOffset, ty * tileOffset)
        field.drawCell(num, size, a)
        gph.pop()
      end
      
    end
  end
end

return field