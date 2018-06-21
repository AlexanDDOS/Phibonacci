fib = require "fib" --Fibonacci number module
field = require "field" --Game field module
button = require "button" --Button module
fontArrs = require "fonts" --Font arrays

score = 0 --Game score


function love.conf(t)
    t.version = "11.1"                  -- The LÖVE version this game was made for (string)
 
    t.audio.mixwithsystem = true        -- Keep background music playing when opening LÖVE (boolean, iOS and Android only)
 
    t.window.title = "Phibonacci"         -- The window title (string)
    t.window.icon = "./icon.png"                -- Filepath to an image to use as the window's icon (string)
 
    t.modules.audio = false             -- Enable the audio module (boolean)
    t.modules.data = false              -- Enable the data module (boolean)
    t.modules.event = false              -- Enable the event module (boolean)
    t.modules.font = false               -- Enable the font module (boolean)
    t.modules.graphics = true           -- Enable the graphics module (boolean)
    t.modules.image = false              -- Enable the image module (boolean)
    t.modules.joystick = true           -- Enable the joystick module (boolean)
    t.modules.keyboard = false           -- Enable the keyboard module (boolean)
    t.modules.math = true               -- Enable the math module (boolean)
    t.modules.mouse = true              -- Enable the mouse module (boolean)
    t.modules.physics = false            -- Enable the physics module (boolean)
    t.modules.sound = false              -- Enable the sound module (boolean)
    t.modules.system = true             -- Enable the system module (boolean)
    t.modules.thread = false             -- Enable the thread module (boolean)
    t.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    t.modules.touch = false              -- Enable the touch module (boolean)
    t.modules.video = false              -- Enable the video module (boolean)
    t.modules.window = true             -- Enable the window module (boolean)
end

--[[Mobile mode forces the window to be psudo-vertical and rotates it 90deg counterclockwise.
Say thanks to men, who ported LÖVE to the mobile platforms.]]
mobileMode = love.system.getOS()
mobileMode = mobileMode == 'Android' or mobileMode == 'iOS' or false

winW, winH = love.graphics.getDimensions()

if mobileMode then
  winW, winH = winH, winW
end

love.window.setMode(winW, winH, {resizable = true})

function getOrientation()
  return mobileMode and -1 or winW - winH -- Horizontal = >0, Vertical <0, Square window = 0
end
winOrientation = getOrientation()

fonts = {}
fonts.latoB = fontArrs.newFontArray('assets/fonts/lato/Lato-Black.ttf', 16, 8)
fonts.lato = fontArrs.newFontArray('assets/fonts/lato/Lato-Regular.ttf', 16, 1)

buttons = {}
buttons.restart = button.new(0, 0, 32, 16, "Restart")
buttons.undo = button.new(0, 0, 32, 16, "Undo")

local cellSize, fieldOffset, fieldEnd
local function updateSizes()  
  cellSize = winH / 5
  fieldOffset = winH / 4 - cellSize
  if winOrientation < 0 then
    cellSize = winW / 5
    fieldOffset = winW / 4 - cellSize
  end
  fieldEnd = cellSize * 4.2 + fieldOffset
  
  fonts.latoB:refresh(cellSize)
  fonts.lato:refresh(cellSize / 3)
  
  for k, v in pairs(buttons) do
    v.w = fonts.lato[1]:getWidth(v.label)
    v.h = cellSize / 3 * 1.25
    if winOrientation < 0 then
      v.x = fieldOffset
      v.y = fieldEnd
    else
      v.x = fieldEnd
      v.y = fieldEnd - v.h * 1.1
    end
  end
  buttons.undo.x = buttons.undo.x + buttons.restart.w * 1.05
  
  if buttons.restart.x + buttons.restart.w > winW then
    winW = buttons.restart.x + buttons.restart.w * 1.05
    love.window.updateMode(winW, winH)
    return updateSizes()
  elseif buttons.undo.x + buttons.undo.w > winW then
    buttons.undo.x = fieldEnd
    buttons.restart.y = buttons.restart.y - buttons.restart.h * 1.1
  end
  
  
end
updateSizes()

function love.load(args)
  if args[#args] == '-debug' then
    require("mobdebug").start()
  end
  newGame()
end

function love.resize(w, h)
  if mobileMode then
    winW, winH = h, w
  else
    winW, winH = w, h
  end
  winOrientation = getOrientation()
  updateSizes()
end

function love.update(dt)
  field.updAnim(dt)
end

function newGame()
  score = 0
  gameOver = false
  
  field.clear()
  for i = 1, field.w * field.h do
    field.tiles[i] = field.tiles[i] or false
    field.oldTiles[i] = field.tiles[i]
  end
  field.randomTile()
end

function love.touchmoved(id, x, y, dx, dy, pressure)
  --Remember the screen is rotated on mobile platforms
  if dx < -0.5 then
    field.move(1) --up
  elseif dx > 0.5 then
    field.move(3) --down
  elseif dy > 0.5 then
    field.move(2) --Left
  elseif dy < -0.5 then
    field.move(0) --right
  end
end

function love.mousepressed(x, y, buttton, isTouch)
  if mobileMode then
    x, y = winW - y, x
  end
  
  if buttons.restart:hasPoint(x, y) then
    newGame()
  elseif buttons.undo:hasPoint(x, y) then
    field.undo()
  end
end

function love.keypressed(key, scancode, isRepeat)
  if key == 'escape' then
    os.exit()
  end
  if scancode == 'left' then
    field.move(2)
  elseif scancode == 'right' then
    field.move(0)
  elseif scancode == 'up' then
    field.move(1)
  elseif scancode == 'down' then
    field.move(3)
  end
end


love.graphics.setBackgroundColor(1, 1, 1)

function love.draw()
  
  if mobileMode then
    love.graphics.translate(winH/2, winW/2)
    love.graphics.rotate(-math.pi / 2)
    love.graphics.translate(-winW/2, -winH/2)
  end
  
  love.graphics.setColor(1, 1, 1)
  love.graphics.push()
  love.graphics.translate(fieldOffset, fieldOffset)
  field.draw(cellSize, cellSize / 20)
  love.graphics.pop()
  
  love.graphics.setColor(0, 0, 0)
  love.graphics.setFont(fonts.lato[1])
  
  if winOrientation < 0 then
    love.graphics.printf('Score: '..score, fieldEnd / 2, fieldEnd, fieldEnd / 2, 'right')
  else
    love.graphics.printf('Score: '..score, fieldEnd, fieldOffset, winW - fieldEnd, 'left')
  end
  
  for k, v in pairs(buttons) do
    v:draw({0, 0, 0.75}, {1, 1, 1})
  end
  
  if gameOver then
    love.graphics.setFont(fonts.latoB[1])
    love.graphics.setColor(0.75, 0, 0)
    love.graphics.printf('Game over!', fieldOffset, fieldEnd / 2 - cellSize * 1.5, fieldEnd - fieldOffset, 'center')
  end
end
