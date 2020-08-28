-- Variables --
local GUIElements = {
	CanvasObject	=	{"CanvasObject.lua", 0x01},
	TextArea		=	{"TextArea.lua", 0x02},
	Button			=	{"Button.lua", 0x04},
	Input			=	{"Input.lua", 0x08},
    List			=	{"List.lua", 0x08},
	ScrollIndicator	=	{"ScrollIndicator.lua", 0x10},
}

local dependencies = {
	CanvasObject	=	{};
	TextArea		=	{"CanvasObject"},
	Button			=	{"CanvasObject", "TextArea"},
	Input			=	{"CanvasObject"},
    List			=	{"CanvasObject"},
	ScrollIndicator	=	{"CanvasObject"},
}

local lookup = {
	black		=	"f";
	red			=	"e";
	green		=	"d";
	brown		=	"c";
	blue		=	"b";
	purple		=	"a";
	cyan		=	"9";
	lightGrey	=	"8";
	lightGray	=	"8";
	grey		=	"7";
	gray		=	"7";
	print		=	"6";
	lime		=	"5";
	yellow		=	"4";
	lightBlue	=	"3";
	magenta		=	"2";
	orange		=	"1";
	white		=	"0";
}

local reverseLookup = {
	[ "f" ]	=	32768;
	[ "e" ]	=	16384;
	[ "d" ] =	8192;
	[ "c" ] =	4096;
	[ "b" ] =	2048;
	[ "a" ] =	1024;
	[ "9" ] =	512;
	[ "8" ] =	256;
	[ "7" ] =	128;
	[ "6" ] =	64;
	[ "5" ] =	32;
	[ "4" ] =	16;
	[ "3" ] =	8;
	[ "2" ] =	4;
	[ "1" ] =	2;
	[ "0" ] =	1;
}
-- Variables --


-- Functions --
local function bAssert ( state, msg, errLevel )
	--[[
		Basically a better assert in that way that it faults the caller, not the called function
	]]--
	if not state then
		error( msg, 3+( type( errLevel ) == "number" and errLevel or 0 ) )
	end
end

local function loadElement(name, env)
	return loadfile(GUIElements[name][1], env)
end

function createGUIObject( args, objectType, parent, redirect )
	local self, object = {}, parent

	local environment = {
		lookup			=	lookup;
		reverseLookup	=	reverseLookup;
		bAssert			=	bAssert;
		self			=	self;
		term			=	redirect or term;
	}

	setmetatable(environment, {__index=_G})

	for k, v in pairs(dependencies[objectType]) do
		object = loadElement(v, environment)(args, object)
	end

	object = loadElement(objectType, environment)(args, object)

	return object
end

function checkCanvasForClick( element, x, y )
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

function lookupColor( color )
	return lookup[ color ]
end

function setPalette( tPalette, wrap )
	assert( type( tPalette ) == "table", "Palette must be given in table form" )

	local term = wrap or term

	local colourIndex

	for k, v in pairs(tPalette) do
		if lookup[ k ] then
			colourIndex = reverseLookup[lookup[k]]
		end

		colourIndex = colourIndex or reverseLookup[k]

		if colourIndex then
			term.setPaletteColor( colourIndex,
				bit.band( 255, bit.brshift( v, 16 ) )/255,
				bit.band( 255, bit.brshift( v, 8 ) )/255,
				bit.band( 255, v )/255
		 	)

			colourIndex = nil
		end
	end

	return true
end

function loadUIFile( sPath, tEnvironment )
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

function setPath(sPath)
	sPath = sPath:match("[\\/]$") and sPath or sPath .. "/"

	for k, v in pairs(GUIElements) do
		v[1] = sPath .. v[1]:match("[\\/]?(.+)$")
	end
end
-- Functions --


-- Older versions --
if not term.blit then
	term.blit = function( text, fg, bg )
		while #text > 0 do
			local fg_match, bg_match = fg:match( fg:sub( 1, 1 ) .. "+" ), bg:match( bg:sub( 1, 1 ) .. "+" )
			local fg_color, bg_color = fg_match and fg_match:sub( 1, 1 ), bg_match and bg_match:sub( 1, 1 )
			local len = math.min( fg_match and #fg_match or #text, bg_match and #bg_match or #text )

			if fg_color and reverseLookup[ fg_color ] then
				term.setTextColor( reverseLookup[ fg_color ] )
			end

			if bg_color and reverseLookup[ bg_color ] then
				term.setBackgroundColor( reverseLookup[ bg_color ] )
			end

			term.write( text:sub( 1, len ) )
			text, fg, bg = text:sub( len+1 ), fg:sub( len+1 ), bg:sub( len+1 )
		end
	end
end
-- Older versions --
