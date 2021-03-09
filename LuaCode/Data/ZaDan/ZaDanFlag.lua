--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-11 13:09:23
--=========================================================================

ZaDanFlag = Flag:New{ Name = "ZaDanFlag" }

local My, base = ZaDanFlag, Flag

----BEG PUBLIC

function My:Init()
	base.Init(self)
	ZaDanMgr.eZaDan:Add(self.Update, self)
	ZaDanMgr.eInfo:Add(self.Update, self)
	PropMgr.eUpdate:Add(self.Update, self)
end

----END PUBLIC

function My:Update()
	self.red = false
	self:ItemChanged()
	if not self.red then self:TimesChanged() end
	self.eChange(self.red)
	if self.red then
		SystemMgr:ShowActivity(ActivityMgr.ZADAN)
	else
		SystemMgr:HideActivity(ActivityMgr.ZADAN)
	end
end

function My:ItemChanged()
	local id = ZaDanMgr:GetHammarID()
	local num = ItemTool.GetNum(id)
	local count = ZaDanMgr:GetOneConHarm()
	num = num or 0
  	if num >= count then
		self.red = true
	end
end

function My:TimesChanged(msg)
	local times, tnum ,id, num = ZaDanMgr.times, ZaDanMgr:GetConfigNum()
	local getDic, get = ZaDanMgr.getDic
	for i, v in ipairs(ZaDanAddUpCfg) do
		id = v.id
		num = v.num
		if tnum == num then
			local val = getDic[tostring(id)] or 1
			if  val ~= 3 then
				if times >= v.cond then
					self.red = true
					break
				end
			end
		end 
	end
end


return My