-- Variables --
local rawArgs = {...}

local object = rawArgs[2]
local args = rawArgs[1]
object.GUIObjectType = 0x02

bAssert(type(args.text) == "nil" or type(args.text) == "table", "Text must be given in table form", 1)
bAssert(type(args.variables) == "nil" or type(args.variables) == "table", "Variables must be given in table form", 1)

if args.text then
    for k, v in pairs(args.text) do
        bAssert(type(v) == "string", "Malformed text", 1)
    end
end

self.text = args.text or {}
self.variables = args.variables or {}
self.formattedText = {}

if type(args.margin) == "number" then
    self.margin_left, self.margin_right, self.margin_top, self.margin_bottom = args.margin, args.margin, args.margin, args.margin
end

self.margin_left = type(args.margin_left) == "number" and args.margin_left or self.margin_left or 0
self.margin_right = type(args.margin_right) == "number" and args.margin_right or self.margin_right or 0
self.margin_top = type(args.margin_top) == "number" and args.margin_top or self.margin_top or 0
self.margin_bottom = type(args.margin_bottom) == "number" and args.margin_bottom or self.margin_bottom or 0
-- Variables --


-- Functions --
local function insertVariables ( text, variables )
	return text:gsub( "%%%%(.-);", function ( varName )
		return variables[ varName ] or "(var:" .. varName .. ")"
	end )
end

local function formatText( text, xSize )
    if xSize < 1 then
        return {""}
    end

    local formatted = {}
    local newFormatted, xPos = {}
    local formattingOptions = {} -- 1, 2, 3 (left, middle, right)
    local newFormattingOptions = {} -- New formatting for processed text
    local currentFormatting, firstMatch = 1

    for k, v in pairs(text) do
        v = insertVariables(v, self.variables)
        formatted[#formatted+1] = ""
        formattingOptions[#formattingOptions+1] = currentFormatting
        firstMatch = v:match("^%s*[&$][RrMmLl];")

        for match in v:gmatch("[&$]?[^&$]*") do
            local formattingSign = match:match("^%s*[&$]([RrMmLl]);")

            if formattingSign then
                if not firstMatch then
                    formatted[#formatted+1] = ""
                    formattingOptions[#formattingOptions+1] = 1
                end

                formatted[#formatted] = formatted[#formatted] .. match:match("^[&$][RrMmLl];(.*)")
                currentFormatting = formattingSign:lower() == "l" and 1 or formattingSign:lower() == "m" and 2 or 3
                formattingOptions[#formattingOptions] = currentFormatting
            else
                formatted[#formatted] = formatted[#formatted] .. match
            end

            firstMatch = false
        end
    end

    for i = 1, #formatted do
        newFormatted[#newFormatted+1] = ""
        xPos = 1
        currentFormatting = formattingOptions[i]
        newFormattingOptions[ #newFormattingOptions+1 ] = currentFormatting

        for match in formatted[i]:gmatch("%s*%S*") do
            local withoutColor = match:gsub("[&$][%xOo];", "")

            if unicode.len( withoutColor ) > xSize-xPos+1 then
                while unicode.len( withoutColor ) > xSize do
                    local rest = xSize-unicode.len( newFormatted[ #newFormatted ]:gsub("[$&][%xRrLlMmo];", "") )
                    local currPos, actPos = 0, 0

                    while currPos < unicode.len( match ) do
                        if not unicode.sub( match, currPos ):match( "^[$&][%xo];" ) then
                            if actPos >= rest-1 then
                                break
                            end
                            currPos = currPos + 1
                            actPos = actPos + 1
                        else
                            currPos = currPos + 3
                        end
                    end

                    newFormatted[ #newFormatted ] = newFormatted[ #newFormatted ] .. unicode:sub( match, 1, currPos ) .. ( xSize > 1 and "-" or "" )
                    match = unicode.sub( match, currPos+( xSize > 1 and 1 or 0 ) )
                    withoutColor = match:gsub( "[$&][%xOo];", "" )

                    if unicode.len( withoutColor ) > xSize then
                        newFormatted[ #newFormatted+1 ] = ""
                        newFormattingOptions[ #newFormattingOptions+1 ] = currentFormatting
                    end
                end

                match = match:match( "%S+" )
                newFormatted[ #newFormatted+1 ] = match
                newFormattingOptions[ #newFormattingOptions+1 ] = currentFormatting
                xPos = unicode.len( match:gsub( "[$&][%xo];", "" ) ) + 1
            else
                newFormatted[ #newFormatted ] = newFormatted[ #newFormatted ] .. match
                xPos = xPos + unicode.len( match:gsub( "[$&][%xo];", "" ) )
            end
        end
    end

    for k, v in pairs(newFormatted) do
        if newFormattingOptions[k] == 2 then
            newFormatted[k] = (" "):rep( math.floor( ( xSize-unicode.len( v:gsub( "[&$][%xOo];", "" ) ) )/2 ) ) .. v
        elseif newFormattingOptions[k] == 3 then
            newFormatted[k] = (" "):rep( xSize-unicode.len( v ) ) .. v
        end
    end

    return newFormatted
end

local function formatColors( text, original_fg, original_bg )
    local current_fg, current_bg = original_fg, original_bg
    local match, color_match
    local formatted = {}

    for k, v in pairs(text) do
        formatted[#formatted+1] = {"", "", ""}

        while #v > 0 do
            color_match = v:match("^[$&][%xOo];")

            if not color_match then
                match = v:match("(.-)[$&][%xOo];")
            end

            if color_match then
                if color_match:sub(1, 1) == "&" then
                    current_fg = color_match:sub(2, 2)
                    current_fg = current_fg:lower() == "o" and original_fg or current_fg
                else
                    current_bg = color_match:sub(2, 2)
                    current_bg = current_bg:lower() == "o" and original_bg or current_bg
                end

                v = v:sub(4)
            else
                match = match or v

                formatted[#formatted][1] = formatted[#formatted][1] .. match
                formatted[#formatted][2] = formatted[#formatted][2] .. current_fg:rep( unicode.len( match ) )
                formatted[#formatted][3] = formatted[#formatted][3] .. current_bg:rep( unicode.len( match ) )

				v = unicode.sub( v, unicode.len( match )+1 )
            end
        end
    end

    return formatted
end

local function processText()
    self.formattedText = formatColors(formatText(self.text, self.boundaries.x2-self.boundaries.x1-self.margin_left-self.margin_right+1), self.fg_color, self.bg_color)
end

local function draw()
	if #self.boundaries == 0 or self.forcedCalculation then
		self.boundaries, self.overhangs = object.getBounds()
	end

	if #self.formattedText == 0 or self.forcedCalculation then
		processText()
		self.forcedCalculation = false
	end

	local lineLength = self.boundaries.x2-self.boundaries.x1-self.overhangs.left-self.overhangs.right+1

	if lineLength < 1 then
		return
	end

	-- Cut off the text if the TextArea has an overhang to the left or right
	local textX1 = 1+self.overhangs.left

	--[[
		The starting position for text drawing has to remove overhanging margins to correctly
		calculate the positions
	]]--
	local marginTop = self.overhangs.top < self.margin_top and self.margin_top-self.overhangs.top or self.overhangs.top
	local marginBottom = self.overhangs.bottom < self.margin_bottom and self.margin_bottom-self.overhangs.bottom or self.overhangs.bottom
	local textPos

	gpu.setBackground( tonumber( self.bg_color, 16 ), true )
	gpu.fill(
		self.boundaries.x1+self.overhangs.left,
		self.boundaries.y1+self.overhangs.top,
		self.boundaries.x2-self.boundaries.x1-self.overhangs.left-self.overhangs.right+1,
		self.boundaries.y2-self.boundaries.y1-self.overhangs.top-self.overhangs.bottom+1,
		" "
 	)

	for y = self.boundaries.y1+marginTop, self.boundaries.y2-marginBottom do
		textPos = y-self.boundaries.y1-self.margin_top+1

		screen.setCursorPos( self.boundaries.x1+self.overhangs.left+self.margin_left, y )

		if self.formattedText[ textPos ] then
			screen.blit(
				unicode.sub( self.formattedText[textPos][1], textX1, lineLength+textX1-1 ),
				unicode.sub( self.formattedText[textPos][2], textX1, lineLength+textX1-1 ),
				unicode.sub( self.formattedText[textPos][3], textX1, lineLength+textX1-1 )
			)
		end
	end

	for k, v in pairs(self.children) do
		v.draw()
	end
end

local function setText( text )
    bAssert(type(text) == "table", "Text must be given in table form", 1)

    self.text = {}

    for k, v in pairs(text) do
        if type(v) == "string" then
            self.text[#self.text+1] = v
        end
    end

    if #self.boundaries == 0 or self.forcedCalculation then
        self.boundaries = object.getBounds()
    end

    processText()
end

local function setVariable( name, value )
    self.variables[name] = value
    self.forcedCalculation = true
end

local function getText()
    local text = {}

    for i = 1, #self.text do
        text[i] = self.text[i]
    end

    return text
end
-- Functions --

-- Returning of element --
object.draw = draw
object.setText = setText
object.getText = getText
object.setVariable = setVariable

return object
-- Returning of element --
