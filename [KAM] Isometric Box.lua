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
      
  ISOMETRIC BOX GENERATOR 1.0 for Aseprite (https://aseprite.org)
  Project page: https://darkwark.itch.io/isobox-for-aseprite
   
    by Kamil Khadeyev (@darkwark)
    Twitter: http://twitter.com/darkwark
    Dribbble: http://dribbble.com/darkwark
    Website: http://darkwark.com

  (c) 2018, November 
  All rights reserved or something
  
  Features:
    + Customize X, Y and Z size of the box
    + Customize colors for each side of the box
    + Custom Stroke and Highlight colors
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
local c = app.fgColor;

-- Default colors:
local colors = {
  stroke = Color{h=0, s=0, v=0, a=255},
  top = app.fgColor,
  left = Color{h=c.hsvHue, s=c.hsvSaturation+0.3, v=c.hsvValue-0.1, a=255},
  right = Color{h=c.hsvHue, s=c.hsvSaturation+0.3, v=c.hsvValue-0.4, a=255},
  highlight = Color{h=c.hsvHue, s=c.hsvSaturation-0.2, v=c.hsvValue+0.2, a=255}
}

-- Use 3px corner by default:
local use3pxCorner = false

-- Default Max Sizes:
local maxSize = {
  x = math.floor(app.activeSprite.width/4), 
  y = math.floor(app.activeSprite.width/4), 
  z = math.floor(app.activeSprite.height/2)
}

local separatedLayer = true

---------------------------------------
-- Colors Utility --
---------------------------------------
local function colorAsPixel(color)
  return app.pixelColor.rgba(color.red, color.green, color.blue, color.alpha)
end

local function isColorEqual(a, b)
  local pc = app.pixelColor
  
  return pc.rgbaR(a) == pc.rgbaR(b) and
         pc.rgbaG(a) == pc.rgbaG(b) and
         pc.rgbaB(a) == pc.rgbaB(b) and
         pc.rgbaA(a) == pc.rgbaA(b)
end

local function isColorEqualAt(x, y, color)
  local pc = app.pixelColor
  local pickedColor = app.activeImage:getPixel(x, y)

  return isColorEqual(pickedColor, color)
end
List = {}
function List.new()
	return { first = 0, last = -1}
end
function List.pushleft (list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end

function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end

function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

function List.popright (list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end
---------------------------------------
-- Flood Fill --
-- Paint Bucket Tool implementation --
---------------------------------------
local function floodFill(x, y, targetColor, replacementColor)
  if isColorEqual(targetColor, replacementColor) then return end
  local pixelList = List.new()
  local p = {x, y}
  List.pushright(pixelList, p)
  
  local cx
  local cy
  while(pixelList.last ~= -1) do
    local p = List.popright(pixelList)
    cx = p[1]
    cy = p[2]
	
    if isColorEqualAt(cx, cy, targetColor) then
	  --app.alert("Filling " .. cx .. ", " .. cy)
      app.activeImage:putPixel(cx, cy, replacementColor)
      List.pushright(pixelList, {cx-1,cy})
      List.pushright(pixelList, {cx+1,cy})
      List.pushright(pixelList, {cx,cy+1})
      List.pushright(pixelList, {cx,cy-1})
    end
  end
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


------------ Adding Colors: ------------

local function fillCubeSides(topColor, leftColor, rightColor)
  local centerX = math.floor(app.activeSprite.width/2)
  local centerY = math.floor(app.activeSprite.height/2)
  
  local TRANSPARENT_COLOR = app.pixelColor.rgba(0, 0, 0, 0)
  
  -- Top Color
  floodFill(centerX, centerY-1, TRANSPARENT_COLOR, colorAsPixel(topColor))
  -- Left Color
  floodFill(centerX-2, centerY+1, TRANSPARENT_COLOR, colorAsPixel(leftColor))
  -- Right Color
  floodFill(centerX+1, centerY+1, TRANSPARENT_COLOR, colorAsPixel(rightColor))
end

local function addHighlight(type, xSize, ySize, zSize, color)
  local centerX = math.floor(app.activeSprite.width/2)
  local centerY = math.floor(app.activeSprite.height/2)
  
  -- TYPE1 is for 3px in the middle
  -- TYPE2 is for 2px in the middle
  local alt = (type == 1) and 0 or 1
  
  isoLineUpRight(color, centerX-alt, centerY, xSize-1)
  isoLineUpLeft(color, centerX, centerY, ySize-1) 
  vLine(color, centerX-alt, centerY, zSize-1)
  
  app.activeImage:putPixel(centerX-alt, centerY, app.pixelColor.rgba(255, 255, 255, 255))
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
local dlg = Dialog("[KAM] Isometric Box")
dlg   :separator{ text="Size:" }
      :slider {id="ySize", label="Left:", min=1, max=maxSize.y, value=5}
      :slider {id="xSize", label="Right:", min=1, max=maxSize.x, value=5}
      :slider {id="zSize", label="Height:", min=3, max=maxSize.z, value=10}

      :separator{ text="Colors:" }
      :color {id="color", label="Stroke:", color = colors.stroke}
      :color {id="topColor", label="Top:", color = colors.top}
      :color {id="leftColor", label="Left:", color = colors.left}
      :color {id="rightColor", label="Right:", color = colors.right}
      :color {id="highlightColor", label="Highlight:", color = colors.highlight}

      :separator()
      :radio {id="typeOne", label="Corner:", text="3 px", selected=use3pxCorner}
      :radio {id="typeTwo", text="2 px", selected=not use3pxCorner}

      :separator()
	  :check {id="sepLayer", label="New Layer:", selected=seperatedLayer, onclick=function()
		local sl = not separatedLayer
		separatedLayer = sl
		end
	  }
	  :separator()
      :button {id="ok", text="Add Box",onclick=function()
          local data = dlg.data
          --app.transaction(function()
		local cubeType = data.typeOne and 1 or 2
		
		newLayer("Cube("..data.xSize.." "..data.ySize.." "..data.zSize..")")
		drawCube(cubeType, data.xSize, data.ySize, data.zSize, data.color)
		fillCubeSides(data.topColor, data.leftColor, data.rightColor)
		addHighlight(cubeType, data.xSize, data.ySize, data.zSize, data.highlightColor)
		if(not separatedLayer) then app.command.MergeDownLayer() end
          --end)
          --Refresh screen
          app.command.Undo()
          app.command.Redo()
        end
      }
      :show{wait=false}

---------------------------------------

