require( "OSUtil", package.seeall )
--set your path, default current path.
local path = ""
--set your output path, default current path "__pkgs__" dir.
local outputPath = ""
--pkgs you don't wanna change for special reasons
local exceptList = 
{
	CCBone=1,
	ColliderBody=1,
	CCSkin=1,
	CCSGUIReader=1,
	CCSSceneReader=1,
	CCDatas=1,
	json_batchallocator=1,
	json_tool=1,
	reader=1,
	value=1,
	UISwitch=1,
	LayoutParameter=1,
	--UIWidget=1,
}

local SKIP_MODE = 0
local WRITE_MODE = 1

local NO_BRACE = 0
local IN_BRACE = 1

local function classResolve( cls )
	local cont = ""
	local decalr = nil
	local publicBlock = nil
	local brace = NO_BRACE
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
				publicBlock = string.gsub( publicBlock, "/%*.-%*/", "")
				cont = cont..publicBlock.."\n"
			end
			publicBlock = nil
		end
		--for CocoStudio
		line = string.gsub( line, "const char %*string", "const char %*stringValue" )
		--remove the function body defined in header
		line = string.gsub( line, "{.-};", ";" )
		--3.remove public protect and private
		--4.remove the decalration of class member variable
		--5.remove member functions declared as private or protected
		--print( mode, brace )
		if string.match(line,"%s*public:%s*") and mode == SKIP_MODE then
			mode = WRITE_MODE
		elseif mode == WRITE_MODE and brace == IN_BRACE and string.match(line,"%s*};%s*") then
			brace = NO_BRACE
			publicBlock = publicBlock..";\n"
		elseif mode == WRITE_MODE and (string.match(line,"%s*private:%s*") or string.match(line,"%s*protected:%s*") or (string.match(line,"%s*};%s*") and not string.match(line,"%s*{.-};%s*")) ) then
			writePublicBlock()
			mode = SKIP_MODE
		elseif mode == WRITE_MODE and string.match(line,"%s*public:%s*") then
			writePublicBlock()			
		end
		--print( line, mode, brace )
		if not string.match(line,"%s*public:%s*") and not string.match(line,"%s*};%s*") and mode == WRITE_MODE then
			if publicBlock == nil then
				publicBlock = ""
			end
			--remove inline keyword for declaration and implementation
			local inline = string.match( " "..line, "%s*[^%S]inline[^%S]%s*" )
			if string.match( line, "{" ) then
				brace = IN_BRACE
			end
			if brace == NO_BRACE and not string.match(line, "%s*//.-%s") and not inline then
				publicBlock = publicBlock..line..(string.match(line, ";") and "\n" or "")
			end
		end
	end  )
	cont = cont.."\n};\n"
	return cont
end

local function getPKGContent( header )
	local content = ""
	--0.remove all comments
	header = string.gsub( header, "/%*.-%*/", "")
	--1.enum keeps the same
	string.gsub( header, "(enum[^%S].-}.-;)", function(enum)
		--print( enum )
		if string.match( enum, "}%s*%w+%s*;" ) then
			enum = "typedef "..enum
		end
		content = content .. enum .. "\n\n"
	end )
	--remove declared class header
	header = string.gsub( header, "%s*class%s%w-%s-;", "")
	--get class content
	string.gsub( header, "(\nclass.-{.-\n};\n)", function(cls)
		content = content .. classResolve( cls ) .. "\n\n"
	end )
	return content
end

path = ( path == "" and OSUtil.getCurPath() or path )
outputPath = ( outputPath == "" and path.."/__pkgs__" or outputPath )
print( path, outputPath )
OSUtil.removeDir( outputPath )
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
	filename = string.match( fullFileName, ".+"..OSUtil.getOSSp().."(.-)%.h" )
	if not exceptList[filename] then
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
end
