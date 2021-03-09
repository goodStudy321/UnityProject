--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-10 15:00:49
-- 装备副本引导,一次性引导,条件不可重复利用
--=========================================================================

GuideEquipCopyCond = GuideCond:New{ Name = "GuideEquipCopyCond" }

local My = GuideEquipCopyCond


function My:Init()
	self.curSceneId = nil
	self.isGuide = nil
	UserMgr.eLvEvent:Add(self.UpdateLevel, self)
	SceneMgr.eChangeEndEvent:Add(self.OnScene, self)  
end

function My:OnScene()
	self.curSceneId = User.SceneId
end

function My:UpdateLevel()
	local lv = User.MapData.Level
	local curSId = self.curSceneId
	if curSId == nil then
		return
	end
	curSId = tostring(curSId)
	local sType = SceneTemp[curSId].maptype
	if sType == 2 then
		return
	end

	local guideDic = GuideMgr.trigedDic
	local state = guideDic["53"]

	local copyLv = SystemOpenTemp["404"].trigParam
	local isGuide = self.isGuide
	if isGuide == true then
		return
	end
	if state == true then
		return
	end
	if lv >= copyLv then
		self.isGuide = true
		self:Start()
		-- UserMgr.eLvEvent:Remove(self.UpdateLevel, self)
    	-- SceneMgr.eChangeEndEvent:Remove(self.OnScene, self)
	end
end

function My:Start()
	for i,v in ipairs(GuideCfg) do
		if v.ty == 5 then
			self.success(self,v)
			break
		end
	end
end

function My:Dispose()
	self.curSceneId = nil
	self.isGuide = nil
	UserMgr.eLvEvent:Remove(self.UpdateLevel, self)
    SceneMgr.eChangeEndEvent:Remove(self.OnScene, self)
end


return My