--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-10 17:03:16
--=========================================================================

ZaDanInfo = Super:New{ Name = "ZaDanInfo" }

local My = ZaDanInfo

----BEG PUBLIC

function My:Set(id, type, itID, num, bind)
	self.id = id or 0
	self.type = type or 1
	self.itID = itID or 0
	self.itNum = num or 0
	self.itBind = bind or false
end

--msg(p_egg)
function My:SetByMsg(msg)
	self:Set(msg.id, msg.egg_type, msg.type_id, msg.num, msg.is_bind)
end

--true:可以砸
function My:CanZa()
	do return self.itID == 0 end
end

function My:Reset()
	--索引(1-8)
	self.id = 0

	--蛋类型(1-3)
	self.type = 1

	--道具ID
	self.itID = 0

	--道具数量
	self.itNum = 1

	--道具是否绑定
	self.itBind = false
end

----END PUBLIC


function My:Dispose()
	self:Reset()
end


return My