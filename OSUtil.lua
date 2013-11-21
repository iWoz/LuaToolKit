OSUtil = {}

function OSUtil.getOSSp()
	return package.config:sub(1,1)
end

function OSUtil.isWin()
	local sp = package.config:sub(1,1)
	if sp == '/' then
		--Unix OS
		return false
	end
	return true
end

REMOVE_DIR = "rm"
MAKE_DIR = "mkdir"
SHOW_PATH = "pwd"
LIST_ALL = "ls"

if OSUtil.isWin() then
	REMOVE_DIR = "rmdir"
	MAKE_DIR = "md"
	SHOW_PATH = "cd"
	LIST_ALL = "dir"	
end

function OSUtil.removeDir( path )
	if OSUtil.isWin() then
		path = string.gsub( path, "/", "\\" )
		os.execute( REMOVE_DIR .. " ".. path.." /S/Q" )
	else
		os.execute( REMOVE_DIR .. " -rf ".. path )
	end
end

function OSUtil.createDir( path )
	if OSUtil.isWin() then
		path = string.gsub( path, "/", "\\" )
		os.execute( MAKE_DIR .. " ".. path )
	else
		os.execute( MAKE_DIR .. " -p ".. path )
	end
end

function OSUtil.getCurPath()
    obj = io.popen(SHOW_PATH)
    path = obj:read("*a"):sub(1,-2)
    obj:close()
    return path
end

function OSUtil.getAllExtCMD( path, ext )
	if OSUtil.isWin() then
		return "cd /d "..path.." && dir /b /s *."..ext
	else
		return "find "..path.." -name *."..ext		
	end
end

function OSUtil.getAllFiles( path, ext )
	local i,t,popen = 0, {}, io.popen
	for filename in popen( OSUtil.getAllExtCMD(path, ext) ):lines() do
		i = i + 1
		t[i] = filename
	end
	return t
end