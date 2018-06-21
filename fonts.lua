local fonts = {}

function fonts.newFontArray(file, maxS, len)
  local arr = {}
  setmetatable(arr, fonts)
  
  return arr:refresh(maxS, len, file)
end

function fonts:refresh(maxS, len, file)
  if len then
    self.len = len
  else
    len = self.len
  end
  
  if file then
    self.filepath = file
  else
    file = self.filepath
  end
  
  self.sizes = {}
  
  for i = 1, math.max(len, #fonts) do
    local font = self[i]
    if font then
      font:release()
      self[i] = nil
    end
    if i < len + 1 then
      local size = maxS / i
      self.sizes[i] = size
      self[i] = love.graphics.newFont(file, size)
    end
  end
  return self
end

function fonts.__index(t, k)
  return rawget(t, k) or fonts[k]
end

return fonts