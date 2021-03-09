--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-06-19 17:56:26
-- 内存工具
--=========================================================================

MemUtil = {Name = "MemUtil"}

local My = MemUtil

--上一次可用内存
My.lastAvaiMem = 0

--内存递增/减少快照
--des(string):描述
function My.Snap(des)
	local avaiMem = Device.AvaiMem
	local lastAvaiMem = My.lastAvaiMem
	des = des or "app"
	if lastAvaiMem < 1 then
		iTrace.Log("Loong", des, " AvaiMem:", avaiMem, "M")
	else
		local dif, str = 0, nil
		if avaiMem < lastAvaiMem then
			dif = lastAvaiMem - avaiMem
			str = " ,decreased:"
		else
			dif = avaiMem - lastAvaiMem
			str = " ,increased:"
		end
		iTrace.Log("Loong", des, " AvaiMem:", avaiMem, "M", str, dif)
	end
	My.lastAvaiMem = avaiMem
end

return My
