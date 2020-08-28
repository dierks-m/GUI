-- Variables --
local rawArgs = {...}

local args = rawArgs[1]
local object = rawArgs[2]

self.listParent = false
self.minScrollBarLength = tonumber( args.minScrollBarLength ) or 3
self.auto_update = true
if args.auto_update == false then
	self.auto_update = false
end

self.listLength = 1
self.listPosition = 1

self.scrollBarLength = -1
self.currentPosition = -1

self.orientation = args.orientation == "horizontal" and "horizontal" or "vertical"

--[[
	Mode - possible modes: "divide" and "normaL"
	Affects behaviour of scroll bar. In "normal" it tries to keep a step size of one pixel,
	in "divide" it tries to evenly divide the scroll bar over the list length: e.g. with three list
	elements, the scroll bar is 1/3 of the entire length and jumps 1/3 of the entire length
	for each scroll operation.
]]--
self.mode = args.mode == "divide" and "divide" or "normal"

local relevantBounds = {
	self.orientation == "vertical" and self.boundaries.y1 or self.boundaries.x1,
	self.orientation == "vertical" and self.boundaries.y2 or self.boundaries.x2,
	self.orientation == "vertical" and self.overhangs.top or self.overhangs.left,
	self.orientation == "vertical" and self.overhangs.bottom or self.overhangs.right
}
-- Variables --


-- Functions --
local function calculateScrollBarLength()
	if self.mode == "normal" then
		self.scrollBarLength = math.max( self.minScrollBarLength, relevantBounds[2]-relevantBounds[1]-self.listLength+1 )
	else
		self.scrollBarLength = math.max( self.minScrollBarLength, math.floor( ( relevantBounds[2]-relevantBounds[1]+1 )/( self.listLength+1 )+0.5 ) )
	end
end

local function calculateCurrentPosition()
	if self.listLength == 0 then
		self.currentPosition = 0
		return
	end

	self.currentPosition = math.floor( ( relevantBounds[2]-relevantBounds[1]-self.scrollBarLength+1 )/self.listLength*self.listPosition+0.5 )
end

local function draw()
	fill(
		self.boundaries.x1 + self.overhangs.left,
		self.boundaries.y1 + self.overhangs.top,
		self.boundaries.x2 - self.overhangs.right,
		self.boundaries.y2 - self.overhangs.bottom,
		self.bg_color
	)

	local startingPosition = relevantBounds[1]+relevantBounds[3]+self.currentPosition
	local endPosition = self.currentPosition + math.min(relevantBounds[2]-relevantBounds[4], relevantBounds[1]+self.scrollBarLength-1)

	if self.orientation == "vertical" then
		fill(
			self.boundaries.x1 + self.overhangs.left,
			startingPosition,
			self.boundaries.x2 - self.overhangs.right,
			endPosition,
			self.fg_color
		)
	else
		gpu.fill(
			startingPosition,
			self.boundaries.y1 + self.overhangs.top,
			endPosition,
			self.boundaries.y2 - self.overhangs.bottom,
			self.fg_color
		)
	end
end

local function setListLength( nLength )
	self.listLength = nLength
	calculateScrollBarLength()
end

local function setListPosition( nPosition, bRedraw )
	self.listPosition = nPosition
	calculateCurrentPosition()

	if self.auto_update and bRedraw ~= false then
		draw()
	end
end

local function triggerCalculation()
	relevantBounds = {
		self.orientation == "vertical" and self.boundaries.y1 or self.boundaries.x1,
		self.orientation == "vertical" and self.boundaries.y2 or self.boundaries.x2,
		self.orientation == "vertical" and self.overhangs.top or self.overhangs.left,
		self.orientation == "vertical" and self.overhangs.bottom or self.overhangs.right
	}
end

local function link( tParent )
	self.listParent = tParent

	return {
		setListLength = setListLength;
		setListPosition = setListPosition;
	}
end
-- Functions --


-- Returning of object --
object.draw = draw
object.link = link
object.triggerCalculation = triggerCalculation

return object
-- Returning of object --
