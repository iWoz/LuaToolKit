require( "OSUtil", package.seeall )
--set your path, default current path.
local path = ""
--set your output path, default current path "__pkgs__" dir.
local outputPath = ""

local SKIP_MODE = 0
local WRITE_MODE = 1

local function classResolve( cls )
	local cont = ""
	local decalr = nil
	local publicBlock = nil
	local mode = SKIP_MODE
	string.gsub( cls, "(.-)\r?\n", function(line)
		--2.remove CC_DLL and multi inherites
		if decalr == nil and string.match(line, "class") then
			decalr = string.gsub( line, "CC_DLL", "" )
			local multi = string.find( decalr, "," )
			if multi then
				decalr = string.sub( decalr, 1, multi - 1 )
			end
			cont = cont..decalr.."\n{\n"
		end
		local function writePublicBlock()
			if publicBlock and string.find( publicBlock, "%(.*%)" ) then
				cont = cont..publicBlock.."\n"
			end
			publicBlock = nil
		end
		--3.remove public protect and private
		--4.remove the decalration of class member variable
		--5.remove member functions declared as private or protected
		if line == "public:" and mode == SKIP_MODE then
			mode = WRITE_MODE
		elseif mode == WRITE_MODE and (line == "private:" or line == "protected:" or line == "};") then
			writePublicBlock()
			mode = SKIP_MODE
		elseif mode == WRITE_MODE and line == "public:" then
			writePublicBlock()			
		end
		if line ~= "public:" and mode == WRITE_MODE then
			if publicBlock == nil then
				publicBlock = ""
			end
			publicBlock = publicBlock..line.."\n"
		end
	end  )
	cont = cont.."\n};\n"
	return cont
end

local function getPKGContent( header )
	local content = ""
	--1.enum keeps the same
	string.gsub( header, "(enum.-}.-;)", function(enum)
		if string.match( enum, "}%w+;" ) then
			enum = "typedef "..enum
		end
		content = content .. enum .. "\n\n"
	end )
	--get class content
	string.gsub( header, "(\nclass.-{.-\n};\n)", function(cls)
		content = content .. classResolve( cls ) .. "\n\n"
	end )
	return content
end

path = ( path == "" and OSUtil.getCurPath() or path )
outputPath = ( outputPath == "" and path.."/__pkgs__" or outputPath )
print( path, outputPath )
OSUtil.createDir( outputPath )

local headers = OSUtil.getAllFiles( path, "h" )
local fullFileName
local fileName
local header
local content
local pkgContent
local pkg
for i = 1,#headers do
	fullFileName = headers[i]
	filename = string.match( fullFileName, ".+"..OSUtil.getOSSp().."(%w-)%.h" )
	--print( fullFileName, filename )
	header = io.open( fullFileName, "r+" )
	content = header:read("*a")
	pkgContent = getPKGContent( content )
	if pkgContent and pkgContent ~= "" then
		io.close(header)
		pkg = io.open(outputPath.."/"..filename..".pkg", "w+")
		pkg:write( pkgContent )
		io.close( pkg )
		print('$pfile "'..filename..'.pkg"')
	end
end
