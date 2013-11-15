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

MAKE_DIR = "mkdir"
SHOW_PATH = "pwd"
LIST_ALL = "ls"

if OSUtil.isWin() then
	MAKE_DIR = "md"
	SHOW_PATH = "cd"
	LIST_ALL = "dir"	
end

function OSUtil.createDir( path )
	os.execute( MAKE_DIR .. " ".. path )
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