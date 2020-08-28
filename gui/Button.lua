-- Variables --
local rawArgs = {...}

local args = rawArgs[1]
local object = rawArgs[2]
object.GUIObjectType = 0x04
-- Variables --


-- Functions --
local function isClicked( x, y )
	if #self.boundaries == 0 or self.forcedCalculation then
		self.boundaries = object.getBounds()
	end

	if x >= self.boundaries.x1+self.overhangs.left and x <= self.boundaries.x2-self.overhangs.right
		and y >= self.boundaries.y1+self.overhangs.top and y <= self.boundaries.y2-self.overhangs.bottom then

		return true
	end
end
-- Functions --


-- Returning of element
object.isClicked = isClicked

return object
-- Returning of element --
