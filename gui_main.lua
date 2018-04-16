-- Variables --
local component = require( "component" )

local GUIElements = {
	CanvasObject	=	{ "CanvasObject", 0x01 };
	TextArea		=	{ "TextArea", 0x02 };
	Button			=	{ "Button", 0x04 };
	List			=	{ "List", 0x08 };
	ScrollIndicator	=	{ "ScrollIndicator", 0x10 };
}

local dependencies = {
	CanvasObject	=	{};
	TextArea		=	{ "CanvasObject" };
	Button			=	{ "CanvasObject", "TextArea" };
	List			=	{ "CanvasObject" };
	ScrollIndicator	=	{ "CanvasObject" };
}

local lookup = {
	black		=	"0";
	red			=	"1";
	green		=	"2";
	brown		=	"3";
	blue		=	"4";
	purple		=	"5";
	cyan		=	"6";
	lightGrey	=	"7";
	lightGray	=	"7";
	grey		=	"8";
	gray		=	"8";
	pink		=	"9";
	lime		=	"a";
	yellow		=	"b";
	lightBlue	=	"c";
	magenta		=	"d";
	orange		=	"e";
	white		=	"f";
}

local standardPalette = {
    0x000000;
    0xb3312c;
    0x3b511a;
    0x51301a;
    0x253192;
    0x7b2fbe;
    0x287697;
    0x999999;
    0x434343;
    0xd88198;
    0x41cd34;
    0xdede6c;
    0x6689d3;
    0xc354cd;
    0xeb8844;
    0xffffff;
}

local screen = {
    xPos    =   0;
    yPos    =   0;
}

local gpu = component.gpu
local term = require( "term" )
-- Variables --


-- Functions --
screen.setCursorPos = function( x, y )
    assert( type(x) == "number" and type(y) == "number", "Arguments must be numbers" )
    screen.xPos = x
    screen.yPos = y
end

screen.blit = function( text, fg, bg )
	local fg_match, bg_match, fg_color, bg_color, len

    while #text > 0 do
        fg_match, bg_match = fg:match( fg:sub( 1, 1 ) .. "+" ), bg:match( bg:sub( 1, 1 ) .. "+" )
        fg_color, bg_color = fg_match and fg_match:sub( 1, 1 ), bg_match and bg_match:sub( 1, 1 )
        len = math.min( fg_match and #fg_match or #text, bg_match and #bg_match or #text )

        if fg_color then
            gpu.setForeground( tonumber( fg_color, 16 ), true )
			fg_color = nil
        end

        if bg_color then
            gpu.setBackground( tonumber( bg_color, 16 ), true )
			fg_color = nil
        end

        gpu.set( screen.xPos, screen.yPos, text:sub( 1, len ) )
        screen.xPos = screen.xPos + len
        text, fg, bg = text:sub( len+1 ), fg:sub( len+1 ), bg:sub( len+1 )
    end
end

screen.getSize = function()
    return gpu.getResolution()
end

screen.setCursorBlink = function( bool )
    term.setCursorBlink( bool )
end

local function bAssert ( state, msg, errLevel )
	--[[
		Basically a better assert in that way that it faults the caller, not the called function
	]]--
	if not state then
		error( msg, 3+( type( errLevel ) == "number" and errLevel or 0 ) )
	end
end

local function loadElement( name, env )
	local file, err = loadfile(GUIElements[name][1], "bt", env)

    if not file then
		if err then
			error( err )
		else
        	error( "File not found" )
		end
    end

    return file
end

local function createGUIObject( args, objectType, parent, redirect )
	local self, object = {}, parent

	local environment = {
		lookup			=	lookup;
		reverseLookup	=	reverseLookup;
		bAssert			=	bAssert;
		self			=	self;
		screen			=	redirect or screen;
		gpu				=	gpu;
	}

	setmetatable( environment, { __index=_G } )

	for k, v in pairs( dependencies[objectType] ) do
		object = loadElement( v, environment )( args, object )
	end

	object = loadElement( objectType, environment )( args, object )

	object.GUIObjectType = GUIElements[ objectType ][2]

	return object
end

local function checkCanvasForClick( element, x, y )
	local matches = {}

	if element.GUIObjectType == GUIElements.Button[2] then
		if element.isClicked(x, y) then
			matches[#matches+1] = element
		end
	end

	for k, v in pairs(element.children) do
		local hits = checkCanvasForClick(v, x, y)

		for i = 1, #hits do
			matches[#matches+1] = hits[i]
		end
	end

	return matches
end

local function lookupColor( color )
	return lookup[ color ]
end

local function setPalette( tPalette )
	assert( type( tPalette ) == "table", "Palette must be given in table form" )

	for k, v in pairs( tPalette ) do
		if lookup[ k ] then
			gpu.setPaletteColor( tonumber( lookup[ k ], 16 ), v )
		elseif tonumber( k, 16 ) then
			gpu.setPaletteColor( tonumber( k, 16 ), v )
		end
	end
end

local function loadUIFile( sPath, tEnvironment )
	local tEnvironment = type( tEnvironment ) == "table" and tEnvironment or {}

	tEnvironment.gui = {
		createGUIObject = createGUIObject;
	}

	local fileContent, err = loadfile( sPath, "bt", tEnvironment )

	if not fileContent then
		if err then
			error( err )
		else
			error( "File not found: " .. sPath )
		end
	end

	return fileContent()
end

local function setPath( sPath )
	sPath = sPath:match( "[\\/]$" ) and sPath or sPath .. "/"

	for k, v in pairs( GUIElements ) do
		v[1] = sPath .. k
	end
end
-- Functions --

for i = 1, #standardPalette do
	gpu.setPaletteColor( i-1, standardPalette[i] )
end

return {
	lookupColor = lookupColor;
	createGUIObject = createGUIObject;
	checkCanvasForClick = checkCanvasForClick;
	setPalette = setPalette;
	loadUIFile = loadUIFile;
	setPath = setPath;
}
