--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-03-10 19:25:52
--=========================================================================

FileUtil = { Name = "FileUtil" }

local My = FileUtil

--path(string):路径
function My.Exist(path)
	local file = io.open(path, "rb")
	if file then file:close() end
	return file ~= nil
end

--path(string):路径
--return(string)
function My.ReadAll(path)
	local file = io.open(path, "r")
	if file == nil then return end
	local str = file:read("*all")
	file:close()
	return str
end

--path(string):路径
--str(string):写入的内容
--mod(string):模式
function My.Write(path, str, mod)
	if path == nil then return end
	str = str or ""
	mod = mod or "w"
	local file = io.open(path, mod)
	file:write(str)
	file:close()
end

return My