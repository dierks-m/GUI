-- Variables --
local rawArgs = {...}

local args = rawArgs[1]
local object = rawArgs[2]
object.GUIObjectType = 0x10


--	Scroll position to shift child elements
self.verticalScroll = 0
self.totalScroll = -1
--	Save element heights so they don't have to be calculated each time
self.childHeights = {}

self.scrollIndicators = {}
-- Variables --


-- Functions --
local function calculateTotalScroll()
	local ySize, childBoundaries
	local listLength = 0

	if #self.boundaries == 0 or self.forcedCalculation then
		self.boundaries, self.overhangs = object.getBounds()
	end

	ySize = self.boundaries.y2-self.boundaries.y1+1

	for k, v in pairs( self.children ) do
		childBoundaries = v.getBounds()
		self.childHeights[ k ] = childBoundaries.y2-childBoundaries.y1+1

		listLength = listLength + childBoundaries.y2-childBoundaries.y1+1
	end

	self.totalScroll = math.max( 0, listLength-ySize )
end

local function setPositions()
	local currentPosition = 0

	for k, v in ipairs( self.children ) do
		v.setBoundaries( { top = currentPosition-self.verticalScroll } )
		currentPosition = currentPosition + self.childHeights[ k ]
	end
end

local function updateScrollIndicators( bRedraw )
	for k, v in pairs( self.scrollIndicators ) do
		v.setListLength( self.totalScroll )
		v.setListPosition( self.verticalScroll, bRedraw )
	end
end

local function draw()
	if self.totalScroll == -1 or self.forcedCalculation then
		calculateTotalScroll()
		setPositions()
		updateScrollIndicators()
		self.forcedCalculation = false
	end

	local currentPosition = 1
    local lineLength = self.boundaries.x2-self.boundaries.x1-self.overhangs.right-self.overhangs.left+1

    for y = self.boundaries.y1+self.overhangs.top, self.boundaries.y2-self.overhangs.bottom do
		term.setCursorPos(self.boundaries.x1+self.overhangs.left, y)
		term.blit((" "):rep(lineLength), ("f"):rep(lineLength), self.bg_color:rep(lineLength))
	end

	for k, v in ipairs( self.children ) do
		if currentPosition-self.verticalScroll+self.childHeights[ k ]-1 > 0 then
			v.draw()
		end

		currentPosition = currentPosition + self.childHeights[ k ]

		if currentPosition-self.verticalScroll > self.boundaries.y2-self.boundaries.y1+1 then
			break
		end
	end
end

local function setScroll( nPosition, bIncDec )
	--[[
		Scroll the list directly to nPosition or, if bIncDec is given, increment or decrement by nPosition

		Returns true if the actual position has changed, false, if not
	]]--

	if bIncDec then
		nPosition = self.verticalScroll + nPosition
	end

	local previousPosition = self.verticalScroll

	if nPosition >= 0 and nPosition <= self.totalScroll then
		self.verticalScroll = nPosition
	elseif nPosition < 0 then
		self.verticalScroll = 0
	else
		self.verticalScroll = self.totalScroll
	end

	if self.verticalScroll ~= previousPosition then
		setPositions()

		for k, v in pairs( self.scrollIndicators ) do
			v.setListPosition( self.verticalScroll )
		end

		return true
	else
		return false
	end
end

local function linkScrollIndicator( tIndicator )
	if not tIndicator.link then
		return
	end

	self.scrollIndicators[ #self.scrollIndicators ] = tIndicator.link( self )

	if self.totalScroll == -1 then
		calculateTotalScroll()
		setPositions()
	end

	self.scrollIndicators[ #self.scrollIndicators ].setListLength( self.totalScroll )
	self.scrollIndicators[ #self.scrollIndicators ].setListPosition( self.verticalScroll, false )
end

local function registerChildren( tElement )
	--[[
		Override the CanvasObject.registerChildren function, so that now changing boundaries
		will cause the list to recalculate
	]]--
	self.children[#self.children+1] = tElement

	calculateTotalScroll()

	tElement.notifyParent = true
end

local function setListPosition( element, newPosition )
    bAssert(newPosition < 1 or newPosition > #self.children + 1, "Attempt to set illegal list position!")
    local childIndex

    for i = 1, #self.children do
        if self.children[i] == element then
            childIndex = i
            break
        end
    end

    if not childIndex then
        return false
    end

    table.remove(childIndex)
    table.insert(self.children, newPosition, element)

    return true
end
-- Functions --


-- Returning of element --
object.draw = draw
object.setScroll = setScroll
object.linkScrollIndicator = linkScrollIndicator
object.updateScrollIndicators = updateScrollIndicators
object.setListPosition = setListPosition

return object
-- Returning of element --
