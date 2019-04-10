--[[---------------------------------------------------------------------
                                        __
 __                                    /\ \__         __
/\_\    ____    ___     ___ ___      __\ \ ,_\  _ __ /\_\    ___
\/\ \  /',__\  / __`\ /' __` __`\  /'__`\ \ \/ /\`'__\/\ \  /'___\
 \ \ \/\__, `\/\ \L\ \/\ \/\ \/\ \/\  __/\ \ \_\ \ \/ \ \ \/\ \__/
  \ \_\/\____/\ \____/\ \_\ \_\ \_\ \____\\ \__\\ \_\  \ \_\ \____\
   \/_/\/___/  \/___/  \/_/\/_/\/_/\/____/ \/__/ \/_/   \/_/\/____/
 __                            _          __
/\ \                         /' \       /'__`\
\ \ \____    ___   __  _    /\_, \     /\ \/\ \
 \ \ '__`\  / __`\/\ \/'\   \/_/\ \    \ \ \ \ \
  \ \ \L\ \/\ \L\ \/>  </      \ \ \  __\ \ \_\ \
   \ \_,__/\ \____//\_/\_\      \ \_\/\_\\ \____/
    \/___/  \/___/ \//\/_/       \/_/\/_/ \/___/
      
  ISOMETRIC BOX GENERATOR LITE 1.0 for Aseprite (https://aseprite.org) 
  Project page: https://darkwark.itch.io/isobox-for-aseprite
  
    by Kamil Khadeyev (@darkwark)
    Twitter: http://twitter.com/darkwark
    Dribbble: http://dribbble.com/darkwark
    Website: http://darkwark.com

  (c) 2018, November 
  All rights reserved or something
  
  Features:
    + Quickly prototype your images using wireframed boxes
    + Customize X, Y and Z size of the box
    + Custom Stroke colors
    + Two types of the box: 3px and 2px corner
  
  Requirements:
    + Aseprite 1.2.10-beta2
    + Color Mode: RGBA
  
  Installation:
    + Open Aseprite
    + Go to `File → Scripts → Open Scripts Folder`
    + Place downloaded LUA script into opened directory
    + Restart Aseprite
  
  Usage:
    + Go to `File → Scripts → [KAM] Isometric Box` to run the script
    + You can also setup a custom hotkey under `Edit → Keyboard Shortcuts`
    
-----------------------------------------------------------------------]]


---------------------------------------
-- USER DEFAULTS --
---------------------------------------
local palette = app.activeSprite.palettes[1]

-- Default colors:
local colors = {
  stroke = Color{r=0, g=0, b=0, a=255},
  fill = Color{r=255, g=255, b=255, a=0},
}

-- Use 3px corner by default:
local use3pxCorner = false

-- Default Max Sizes:
local maxSize = {
  x = math.floor(app.activeSprite.width/4), 
  y = math.floor(app.activeSprite.width/4), 
  z = math.floor(app.activeSprite.height/2) 
}



---------------------------------------
-- Colors Utility --
---------------------------------------
local function colorAsPixel(color)
  return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end

---------------------------------------
-- BASIC LINES --
---------------------------------------
local function hLine(color, x, y, len)
  -- Horizontal Line
  for i = 1, len do
    app.activeImage:putPixel(x+i, y, color)
  end
end

local function vLine(color, x, y, len)
  -- Vertical Line
  for i = 1, len do
    app.activeImage:putPixel(x, y+i, color)
  end
end

---------------------------------------
-- ISOMETRIC LINES --
---------------------------------------
--TODO: Compile these functions into one universal isoLine(direction)
local function isoLineDownRight(color, x, y, len)
  for i=0,len do
    x1 = i*2
    x2 = x1+1
    app.activeImage:putPixel(x+x1, y+i, color)
    app.activeImage:putPixel(x+x2, y+i, color)
  end
end

local function isoLineDownLeft(color, x, y, len)
  for i=0,len do
    x1 = i*2
    x2 = x1+1
    app.activeImage:putPixel(x-x1, y+i, color)
    app.activeImage:putPixel(x-x2, y+i, color)
  end
end

local function isoLineUpRight(color, x, y, len)
  for i=0,len do
    x1 = i*2
    x2 = x1+1
    app.activeImage:putPixel(x+x1, y-i, color)
    app.activeImage:putPixel(x+x2, y-i, color)
  end
end

local function isoLineUpLeft(color, x, y, len)
  for i=0,len do
    x1 = i*2
    x2 = x1+1
    app.activeImage:putPixel(x-x1, y-i, color)
    app.activeImage:putPixel(x-x2, y-i, color)
  end
end

---------------------------------------
-- FINAL CUBE --
---------------------------------------
local function drawCube(type, xSize, ySize, zSize, color)
  --[[
    Dimensions:
      X: right side
      Y: left side
      Z: is height
    
    Type can be 1 or 2:
      1 is for 3px corner
      2 is for 2px corner
  ]]--
  local centerX = math.floor(app.activeSprite.width/2)
  local centerY = math.floor(app.activeSprite.height/2)
  
  local a = (type == 1) and 0 or 1
  local b = (type == 1) and 1 or 0
  
  --top plane
  isoLineUpRight(color, centerX-a, centerY, xSize) --bottom right
  isoLineUpLeft(color, centerX, centerY, ySize) --bottom left
  isoLineUpLeft(color, centerX+xSize*2+b, centerY-xSize, ySize) --top right
  isoLineUpRight(color, centerX-ySize*2-1, centerY-ySize, xSize) --top left

  --bottom plane
  isoLineUpRight(color, centerX-a, centerY+zSize, xSize) --right
  isoLineUpLeft(color, centerX, centerY+zSize, ySize) --left

  --vertical lines
  vLine(color, centerX-a, centerY, zSize) --middle
  vLine(color, centerX-ySize*2-1, centerY-ySize, zSize) --left
  vLine(color, centerX+xSize*2+b, centerY-xSize, zSize) --right
end

---------------------------------------
-- LAYER MANAGEMENT --
---------------------------------------
local function newLayer(name)
  s = app.activeSprite
  lyr = s:newLayer()
  lyr.name = name
  s:newCel(lyr, 1)
  
  return lyr
end


---------------------------------------
-- USER INTERFACE --
---------------------------------------
local dlg = Dialog("[KAM] Isometric Box (Lite)")
dlg   :separator{ text="Size:" }
      :slider {id="ySize", label="Left:", min=1, max=maxSize.y, value=5}
      :slider {id="xSize", label="Right:", min=1, max=maxSize.x, value=5}
      :slider {id="zSize", label="Height:", min=3, max=maxSize.z, value=10}

      :separator{ text="Colors:" }
      :color {id="strokeColor", label="Stroke:", color = colors.stroke}
      --:color {id="fillColor", label="Fill:", color = colors.fill}

      :separator()
      :radio {id="typeOne", label="Corner:", text="3 px", selected=use3pxCorner}
      :radio {id="typeTwo", text="2 px", selected=not use3pxCorner}

      :separator()
      :button {id="ok", text="Add Box",onclick=function()
          local data = dlg.data
          app.transaction(function()
            local cubeType = data.typeOne and 1 or 2

            newLayer("Cube("..data.xSize.." "..data.ySize.." "..data.zSize..")")
            drawCube(cubeType, data.xSize, data.ySize, data.zSize, data.strokeColor)       
          end)
          --Refresh screen
          app.command.Undo()
          app.command.Redo()
        end
      }
      :show{wait=false}

---------------------------------------

