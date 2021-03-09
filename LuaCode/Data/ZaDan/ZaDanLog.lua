--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-10 23:16:18
--=========================================================================

ZaDanLog = Super:New{ Name = "ZaDanLog" }

local My = ZaDanLog

----BEG PUBLIC

function My:Set(et, name, itID)
	--蛋类型
	self.et = et
	--玩家名
	self.name = name
	--道具ID
	self.itID = itID
end

--msg(p_kvs)
function My:SetByMsg(msg)
	self:Set(msg.id, msg.text, msg.val)
end

----END PUBLIC

function My:Update()

end


function My:Dispose()

end


return My