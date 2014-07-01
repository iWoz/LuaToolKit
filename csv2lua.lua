require( "OSUtil", package.seeall )
--set your path, default current path.
local path = ""
--set your output path, default current path "__pkgs__" dir.
local outputPath = "../data"

path = ( path == "" and OSUtil.getCurPath() or path )
outputPath = ( outputPath == "" and path.."/luaConfig" or outputPath )
print( string.format("csv目录路径：%s", path) )
print( string.format("输出的lua目录路径：%s\n", outputPath) )
OSUtil.createDir( outputPath )

print("准备将csv转成lua表...\n")

--最少行数，5行配置信息，至少1行数据
local MIN_ROW = 6

local function getLuaConfig(csvlines)
	if #csvlines < MIN_ROW then
		print(string.format("错误，csv的行数必须大于%d行",MIN_ROW))
		return 
	end

	local conf = "--[[\n"
	local nameForNote = csvlines[1][1]
	local nameForTable = csvlines[1][2]
	local propNames = csvlines[2]
	local propList = csvlines[3]
	local keyList = {}
	for i,v in ipairs(csvlines[4]) do
		if v ~= "" then
			table.insert(keyList, i)
		end
	end
	local typeList = csvlines[5]
	local propNum = 0
	for i,v in ipairs(propList) do
		if v == "" then
			propNum = i - 1
			break
		end
	end
	if #propNames ~= #propList then
		print(string.format("警告，第二行应与第三行列数相同！"))
	end

	--完成注释部分
	conf = conf .. nameForNote .. "\n\n"
	for i = 1,propNum do
		conf = conf .. string.format("%s\t\t%s\n", propList[i], propNames[i])
	end
	conf = conf .. "]]--\n\n"
	--完成主体部分
	conf = conf .. nameForTable .. " = {\n"
	local lineCont
	for i = 6,#csvlines do
		lineCont = csvlines[i]
		if lineCont then
			local key
			--多个主键
			if #keyList > 1 then
				key = '"'
				for k,v in ipairs(keyList) do
					key = key .. lineCont[v] .. (k == #keyList and '' or '_')
				end
				key = key .. '"'
			--单个主键
			else
				key = lineCont[keyList[1]]
				if typeList[keyList[1]] == "str" then
					key = '"'.. key ..'"'
				end
			end
			conf = conf .. "[" .. key .. "] = {"

			local value
			for i,v in ipairs(propList) do
				value = lineCont[i]
				if value ~= "" then
					if typeList[i] == "str" then
						value = '"'..value..'"'
					end
					conf = conf .. v .. ' = ' .. value .. ", "
				end
			end

			conf = conf .. "},\n"
		end
	end
	conf = conf .. "}\n"
	-- print(conf)
	return conf, nameForTable
end

local files = OSUtil.getAllFiles( path, "csv" )

local filename
for i = 1,#files do
	filename = files[i]
	local csv = io.open(filename, "r+")
	local lines = {}
	local lineEmpty = true
	local lineIdx = 1
	for line in csv:lines() do
		lines[lineIdx] = {}
		lineEmpty = true
		for i in string.gmatch(line, "(.-),") do
			if i ~= "" then
				lineEmpty = false
			end
			table.insert(lines[lineIdx], i)
		end
		if lineEmpty then
			lines[lineIdx] = nil
		end
		lineIdx = lineIdx + 1
	end
	io.close(csv)
	local cont, luaName = getLuaConfig(lines)
	lua = io.open(outputPath..'/'..luaName..".lua","w+")
    lua:write(cont)
    io.close(lua)
    print( filename.." -> "..luaName..".lua 完成！")
end