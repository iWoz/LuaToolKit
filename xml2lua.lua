require( "OSUtil", package.seeall )
--set your path, default current path.
local path = ""
--set your output path, default current path "__pkgs__" dir.
local outputPath = ""

local primeKey = "primeKey"
local keySpliter = "_"
local commentIgnore = ".*编辑使用 XMLSpy.*"

local function split(str, pat)
    local t = {}
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
         if s ~= 1 or cap ~= "" then
             t[cap] = cap
         end
         last_end = e+1
         s, e, cap = str:find(fpat, last_end)
     end
    if last_end <= #str then
         cap = str:sub(last_end)
         t[cap] = cap
     end
    return t
end

local function parseargs(s)
    local arg = {}
    local i = 1
    string.gsub(s, "(%w+)%s*=%s*([\"'])(.-)%2", 
        function (w, _, a)
            arg[i] = { k = w, v = a }
            i = i + 1
        end
    )
    return arg
end
    
local function collect(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni,c,label,xarg,empty
    local i,j = 1,1
    while true do
        ni,j,c,label,xarg,empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then 
            break 
        end
        
        if empty == "/" then  -- empty element tag
            table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
        elseif c == "" then   -- start tag
            top = {label=label, xarg=parseargs(xarg)}
            table.insert(stack, top)   -- new level
        else  -- end tag
            local toclose = table.remove(stack)  -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with "..label)
            end
            if toclose.label ~= label then
                error("trying to close "..toclose.label.." with "..label)
            end
            table.insert(top, toclose)
        end
        i = j+1
    end

    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
        table.insert(stack[#stack], text)
    end
    if #stack > 1 then
        error("unclosed "..stack[#stack].label)
    end
    return stack[1]
end

local function getComments( str )
    local comments = ""
    string.gsub(str, "<!%-%-(.-)%-%->", 
        function (w, _)
            if not string.match( w, commentIgnore ) then
                comments = comments.."--[["..w.."--]]"
            end
        end
    )
    return comments.."\n"
end

path = ( path == "" and OSUtil.getCurPath() or path )
outputPath = ( outputPath == "" and path.."/luaConfig" or outputPath )
print( path, outputPath )
OSUtil.createDir( outputPath )

local files = OSUtil.getAllFiles( path, "xml" )
local fileReqs = {}
local t
for i = 1,#files do
    fullfilename = files[i]
    filename = string.match( files[i], "%s?(%w+)%." )

    xml=io.open(fullfilename,"r+")
    str=xml:read("*a")
    io.close(xml)

    t=collect(str)

    local ser=getComments(str)..filename.."_config={\n"
    local row = ""
    local key = ""
    local keys = {}
    local lua
    if t[1].label == "root" then
        local items=t[1]
        for k,v in ipairs(items) do
            if v.label == primeKey then
                key = v.xarg[1].v
                keys = split( key, keySpliter )
            end
            if v.label ~= primeKey then
                row = "{"
                key = ""
                for kk, vv in ipairs(v.xarg) do
                    if keys[vv.k] ~= nil then
                        key = key .. vv.v .. "_"
                    end
                    row = row .. vv.k .. "=" .. "\"" .. vv.v .. "\"" .. ","
                end
                row = row .. "},\n"
                if #key > 1 then
                    key = string.sub( key, 1, #key - 1 )
                end
                if key ~= "" then
                    row = '["' .. key .. '"]=' .. row
                end
                ser = ser .. row
            end
        end
    end
    ser = ser .. "}"

    lua = io.open(outputPath..'/'..filename.."_config.lua","w+")
    lua:write(ser)
    table.insert( fileReqs, filename.."_config" )
    io.close(lua)

    print( fullfilename.." -> "..filename..'.lua Done!')
end

local reqs = ""
for _,v in pairs(fileReqs) do
    reqs = reqs..'require( "data/'..v..'", package.seeall )\n'
end

print( reqs )

dataconfig = io.open(outputPath..'/DataConfig.lua',"w+")
dataconfig:write( reqs )
io.close( dataconfig )