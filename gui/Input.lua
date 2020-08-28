-- Variables --
local rawArgs = {...}

local object = rawArgs[2]
local args = rawArgs[1]
object.GUIObjectType = 0x08

bAssert(type(args.text) == "nil" or type(args.text) == "table", "Text must be given in table form", 1)
bAssert(type(args.variables) == "nil" or type(args.variables) == "table", "Variables must be given in table form", 1)

self.text = args.text or {""}
self.cursorPosition = {
    1, 1, 0, 0
}
self.lastCursorPosition = nil
self.newLineAllowed = not args.newLineForbidden
-- Variables --


-- Functions --
local function setCursorPos( x, y )
    local oldPos_x, oldPos_y = self.cursorPosition[1]+self.cursorPosition[3],
        self.cursorPosition[2]+self.cursorPosition[4]

    if y then
        if y > self.cursorPosition[4]+(self.boundaries.y2-self.boundaries.y1+1) then
            self.cursorPosition[2] = self.boundaries.y2-self.boundaries.y1+1
            self.cursorPosition[4] = math.min(y-self.cursorPosition[2], #self.text-self.cursorPosition[2])

            self.needRedraw = true
        elseif y <= self.cursorPosition[4] then
            self.cursorPosition[2] = 1
            self.cursorPosition[4] = math.max(y-self.cursorPosition[2], 0)

            self.needRedraw = true
        else
            self.cursorPosition[2] = math.min(y-self.cursorPosition[4], #self.text)
        end
    end

    if x ~= self.cursorPosition[1]+self.cursorPosition[3] or y then
        if x > self.cursorPosition[3]+(self.boundaries.x2-self.boundaries.x1+1) then
            self.cursorPosition[1] = self.boundaries.x2-self.boundaries.x1+1
            self.cursorPosition[3] = x-self.cursorPosition[1]
        elseif x <= self.cursorPosition[3] then
            self.cursorPosition[1] = 1
            self.cursorPosition[3] = math.min(math.max(x-self.cursorPosition[1], 0), #self.text[self.cursorPosition[2]+self.cursorPosition[4]])

            self.needRedraw = true
        else
            self.cursorPosition[1] = math.min(x-self.cursorPosition[3], #self.text[self.cursorPosition[2]+self.cursorPosition[4]]+1-self.cursorPosition[3])
        end
    end

    if self.cursorPosition[3] >= #self.text[self.cursorPosition[2]+self.cursorPosition[4]]+1 then
        self.cursorPosition[1] = 1
        self.needRedraw = true
    end

    if self.cursorPosition[1]+self.cursorPosition[3] > #self.text[self.cursorPosition[2]+self.cursorPosition[4]]+1 then
        self.cursorPosition[3] = #self.text[self.cursorPosition[2]+self.cursorPosition[4]]-self.cursorPosition[1]+1
        self.needRedraw = true
    end

    return oldPos_x ~= self.cursorPosition[1]+self.cursorPosition[3] or oldPos_y ~= self.cursorPosition[2]+self.cursorPosition[4]
end

local function setLastCursorPosition( change )
    if change ~= false then
        self.lastCursorPosition = self.cursorPosition[1]+self.cursorPosition[3]
    end
end

local function processEvent( ... )
    local args = {...}
    local xPosition, yPosition =
        self.cursorPosition[1]+self.cursorPosition[3],
        self.cursorPosition[2]+self.cursorPosition[4]

    if args[1] == "char" then
        self.text[yPosition] =
            self.text[yPosition]:sub(1, xPosition-1) ..
            args[2] ..
            self.text[yPosition]:sub(xPosition)

        setCursorPos(xPosition+1)
        setLastCursorPosition()
    elseif args[1] == "key" then
        if args[2] == keys.left then
            setLastCursorPosition(setCursorPos(xPosition-1))
        elseif args[2] == keys.right then
            setLastCursorPosition(setCursorPos(xPosition+1))
        elseif args[2] == keys.up then
            setCursorPos(self.lastCursorPosition, yPosition-1)
        elseif args[2] == keys.down then
            setCursorPos(self.lastCursorPosition, yPosition+1)
        elseif args[2] == keys.home then
            setCursorPos(1)
        elseif args[2] == keys["end"] then
            setCursorPos(#self.text[yPosition]+1)
        elseif args[2] == keys.backspace then
            if #self.text[yPosition] > 0 and xPosition > 1 then
                self.text[yPosition] =
                    self.text[yPosition]:sub(1, xPosition-2) ..
                    self.text[yPosition]:sub(xPosition)
                setCursorPos(xPosition-1)
            else
                if #self.text > 1 and yPosition > 1 then
                    self.text[yPosition-1] = self.text[yPosition-1] .. self.text[yPosition]
                    setCursorPos(#self.text[yPosition-1]+1-#self.text[yPosition], yPosition-1)
                    table.remove(self.text, yPosition)
                end
            end

            setLastCursorPosition()
        elseif args[2] == keys.delete then
            if #self.text[yPosition]:sub(xPosition) > 0 then
                self.text[yPosition] =
                    self.text[yPosition]:sub(1, xPosition-1) ..
                    self.text[yPosition]:sub(xPosition+1)
            elseif #self.text > yPosition then
                self.text[yPosition] = self.text[yPosition] .. self.text[yPosition+1]
                table.remove(self.text, yPosition+1)
            end
        elseif args[2] == keys.enter and self.newLineAllowed then
            table.insert(self.text, yPosition+1, "")
            setCursorPos(1, yPosition+1)
            setLastCursorPosition()
        end
    end
end

local function drawAll()
    if #self.boundaries == 0 or self.forcedCalculation then
		self.boundaries = object.getBounds()
	end

    local lineLength = self.boundaries.x2-self.boundaries.x1+1
    local textToDraw

    for y = self.boundaries.y1, self.boundaries.y2 do
        term.setCursorPos(self.boundaries.x1, y)
        if self.text[y-self.boundaries.y1+1+self.cursorPosition[4]] then
            textToDraw = self.text[y-self.boundaries.y1+1+self.cursorPosition[4]]:sub(self.cursorPosition[3]+1, lineLength+self.cursorPosition[3])
            textToDraw = textToDraw .. (" "):rep(lineLength-#textToDraw > 0 and lineLength-#textToDraw or 0)
        else
            textToDraw = (" "):rep(lineLength)
        end
        term.blit(textToDraw,
            self.fg_color:rep(lineLength),
            self.bg_color:rep(lineLength))
    end

    term.setCursorPos(self.boundaries.x1+self.cursorPosition[1]-1, self.boundaries.y1+self.cursorPosition[2]-1)
end

local function drawCurrentLine()
    if self.needRedraw or #self.boundaries == 0 or self.forcedCalculation then
        drawAll()
        return
    end

    local lineLength = self.boundaries.x2-self.boundaries.x1+1

    term.setCursorPos(self.boundaries.x1, self.boundaries.y1+self.cursorPosition[2]-1)
    term.blit(self.text[self.cursorPosition[2]]:sub(self.cursorPosition[3], lineLength+self.cursorPosition[3]-1),
        self.fg_color:rep(lineLength),
        self.bg_color:rep(lineLength))
end

local function getText()
    local text = {}

    for k, v in pairs(self.text) do
        text[k] = v
    end

    return text
end

local function getCursorPosition()
    return {
        x = self.cursorPosition[1]+self.cursorPosition[3];
        y = self.cursorPosition[2]+self.cursorPosition[4];
    }
end

local function showCursor()
    term.setCursorBlink( true )
    term.setTextColor( reverseLookup[self.fg_color] )
    term.setCursorPos( self.boundaries.x1 + self.cursorPosition[1]-1, self.boundaries.y1+self.cursorPosition[2]-1 )
end
-- Functions --


-- Returning of element --
object.draw = drawCurrentLine
object.processEvent = processEvent
object.getText = getText
object.getCursorPosition = getCursorPosition
object.showCursor = showCursor
return object
-- Returning of element --
