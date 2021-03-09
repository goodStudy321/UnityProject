--region UIMission.lua
--Date
--此文件由[HS]创建生成

require("UI/UIMission/UIMissionGroup")
require("UI/UIMission/UIMissionGroupList")
require("UI/UIMission/UIMissionGroupItem")

UIMission = UIBase:New{Name ="UIMission"}
local M = UIMission

M.OffsetLv = 0
M.RestTimer = {"","","每天0点", "每周一0点"}
M.OpenLv  = {1, 52, 105, 202}

local mMgr = MissionMgr

function M:InitCustom()
	self.Persitent = true;
	local name = "任务面板"
	local trans = self.root
	local T = TransTool.FindChild
	local C = ComTool.Get
	self.Tog1 = T(trans, "Tog1")
	self.Action1 = T(trans, "Tog1/Action")
	self.ANum1 = C(UILabel, trans, "Tog1/Action/Label", name, false)
	self.Tog2 = T(trans, "Tog2")
	self.Action2 = T(trans, "Tog2/Action")
	self.ANum2 = C(UILabel, trans, "Tog2/Action/Label", name, false)
	self.Tog3 = T(trans, "Tog3")
	self.Action3 = T(trans, "Tog3/Action")
	self.ANum3 = C(UILabel, trans, "Tog3/Action/Label", name, false)
	self.Tog4 = T(trans, "Tog4")
	self.Action4 = T(trans, "Tog4/Action")
	self.ANum4 = C(UILabel, trans, "Tog4/Action/Label", name, false)
	self.NoMiss = T(trans, "NoMiss")
	self.RestTimerLab = C(UILabel, trans, "NoMiss/Reset", name, false)
	self.CloseBtn = T(trans, "Close")
	self.Load = T(trans, "Loading")
	self.LoadSlider = C(UISlider, trans, "Loading/Slider", name, false)
	self.LoadTitle = C(UILabel, trans, "Loading/Title", name, false)
	self.LoadRate = C(UILabel, trans, "Loading/Rate", name, false)
	self.LoadIcon = C(UISprite, trans, "Loading/Icon", name, false)
	self.Group = ObjPool.Get(UIMissionGroup)
	self.Group:Init(T(trans, "Miss"), self)
	self:InitEvent()
	self.CurTog = nil
end

function M:InitEvent()
	local E = UITool.SetLsnrSelf
	E(self.Tog1, self.OnClickTog, self, "", false)
	E(self.Tog2, self.OnClickTog, self, "", false)
	E(self.Tog3, self.OnClickTog, self, "", false)
	E(self.Tog4, self.OnClickTog, self, "", false)
	E(self.CloseBtn, self.Close, self, "", false)
end

function M:AddEvent()
	self:SetEvent("Add")
end

function M:SetEvent(fn)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.UpdateLevel ,self)	
	UserMgr.eLvUpdate[fn](UserMgr.eLvUpdate, self.UpdateLevel ,self)	
	
	mMgr.eAddMission[fn](mMgr.eAddMission, self.AddMission, self)
	mMgr.eUpdateMissStatus[fn](mMgr.eUpdateMissStatus, self.UpdateMission, self)
	mMgr.eUpdateMissTarget[fn](mMgr.eUpdateMissTarget, self.UpdateMission, self)
	mMgr.eCompleteEvent[fn](mMgr.eCompleteEvent, self.UpdateMission, self)
	mMgr.eCleanMission[fn](mMgr.eCleanMission, self.CleanMission, self)
	--mMgr.eCleanAllMission[fn](mMgr.eCleanAllMission, self.CleanAllMission, self)
	--mMgr.ePlayMissionEffect[fn](mMgr.ePlayMissionEffect, self.UpdateMission, self)
end

function M:RemoveEvent()
	self:SetEvent("Remove")
end

function M:OpenTog()
	local lv = User.MapData.Level
	if self.Tog1 then self.Tog1:SetActive(self.OpenLv[1] <= lv) end
	if self.Tog2 then self.Tog2:SetActive(self.OpenLv[2] <= lv) end
	if self.Tog3 then self.Tog3:SetActive(LuaTool.Length(MissionMgr.TurnList) > 0 or self.OpenLv[3] <= lv) end
	if self.Tog4 then self.Tog4:SetActive(self.OpenLv[3] <= lv) end
end

function M:OnClickTog(go, reset)
	self.CurTog = go
	local group = self.Group
	if not group then return end
	local show = false
	local showload = false
	local showCBtn = false
	local changePos = false
	group:RestActiveNum()
	local t = 0
	if go.name == self.Tog1.name then
		group:UpdateItem(mMgr.Main)
		show = mMgr.Main ~= nil
		showload = mMgr.Main ~= nil
		t = 1
	elseif go.name == self.Tog2.name then
		local dic = mMgr.FeederList
		group:UpdateDic(dic)
		show = dic ~= nil and LuaTool.Length(dic) > 0
		t = 2
	elseif go.name == self.Tog3.name then
		local dic = mMgr.TurnList
		local dic1 = mMgr.LivenessList
		group:UpdateDic(dic)
		group:UpdateDic(dic1)
		show = (dic ~= nil and LuaTool.Length(dic)>0) or (dic1 ~= nil and LuaTool.Length(dic1)>0)
		 t = 3
		 changePos = true
	elseif go.name == self.Tog4.name then
		local dic = mMgr.FamilyList
		group:UpdateDic(dic)
		local value = dic ~= nil and LuaTool.Length(dic) > 0
		show = value
		showload = value
		t =  4
		showCBtn = group:IsOpenCBtn()
		changePos = true
	end
	group:ShowCBtn(showCBtn)
	group:ChangePos(changePos)
	group:SetActive(show)
	group:Reset(true, reset)
	local noMiss = self.NoMiss
	if noMiss then noMiss:SetActive(not show) end
	local restlab = self.RestTimerLab
	if restlab then
		restlab.gameObject:SetActive(t > 2)
		if t > 0 then
			local str = string.format("[00ff00]%s重置[-]",self.RestTimer[t]) 
			if t == 4 then
				if FamilyMgr:JoinFamily() == false then
					str = string.format("%s[f21919](未加入道庭)[-]",str)
				end
			end
			restlab.text = str
		else
			restlab.text = ""
		end
	end
	self.Load:SetActive(showload)
	self:UpdateLoad()
end

function M:UpdateLevel()
	if self.OffsetLv >= User.MapData.Level then return end
	self:OpenTog()
	local group = self.Group
	if group then group:ChangeLv() end
end

function M:UpdateLoad()
	local slider = 0
	local title = ""
	local rate = ""
	local icon = ""
	local cur = self.CurTog
	if cur == self.Tog1 then
		local mission = mMgr.Main
		if mission then
			local temp = mission.Temp
			if temp then
				local cMgr = ChapterMgr
				local cTemp = cMgr:GetChapter(temp)
				if cTemp then
					title = string.format("%s %s", cTemp.index, cTemp.name)
					local data = cMgr.ChapterDic[tostring(cTemp.id)]
					local cur = 0
					if data then
						cur = data.Num
					end
					rate = string.format("(%s/%s)", cur, cTemp.limit)
					slider = cur / cTemp.limit
				end
			end
		end
		icon = "ZJ icon_linshi"
	elseif cur == self.Tog4 then
		title = "本周完成次数"
		local limit = 0
		local num = 0
		local dic = mMgr.FamilyList
		if dic ~= nil and LuaTool.Length(dic) > 0 then
			for k,v in pairs(dic) do
				limit = v.Temp.ring* v.Temp.turns
				num = v.Succ
				break
			end
		end
		rate = string.format("(%s/%s)", num, limit)
		slider = num / limit
		icon = "sys_5"
	else
		return
	end
	self.LoadSlider.value = slider
	self.LoadTitle.text = title
	self.LoadRate.text = rate
	self.LoadIcon.spriteName = icon
end

function M:UpdateAction()
	local num1 = mMgr.MainRed
	local num2 = mMgr.FeederRed
	local num3 = mMgr.TurnRed
	local num4 = mMgr.FamilyRed
	self.Action1:SetActive(num1 > 0)
	self.Action2:SetActive(num2 > 0)
	self.Action3:SetActive(num3 > 0)
	self.Action4:SetActive(num4 > 0)
	self.ANum1.text = tostring(num1)
	self.ANum2.text = tostring(num2)
	self.ANum3.text = tostring(num3)
	self.ANum4.text = tostring(num4)
end

function M:IsReset(id)
	local miss = mMgr:GetMissionForID(id)
	if miss and miss.Temp then
		local type = miss.Temp.type
		if type == MissionType.Main and self.CurTog.name == self.Tog1.name then
			return true
		elseif type == MissionType.Feeder and  self.CurTog.name == self.Tog2.name then
			return true
		elseif type == MissionType.Turn and  self.CurTog.name == self.Tog3.name then
			return true
		elseif type == MissionType.Family and  self.CurTog.name == self.Tog4.name then
			return true
		end
	end
	return false
end

function M:AddMission(id)
	if self:IsReset(id) == false then return end
	if self.CurTog then
		self:OnClickTog(self.CurTog)
	end
end

function M:UpdateMission(id)
	self:UpdateAction()
	if self:IsReset(id) == true then 
		local group = self.Group
		if group then
			group:UpdateItems()
		end
	end
	self:UpdateLoad()
end

function M:CleanMission(id)
	if self:IsReset(id) == false then return end
	local group = self.Group
	if group then group:CleanMission(id) end
	if self.CurTog then
		self:OnClickTog(self.CurTog)
	end
end

function M:CleanAllMission()
	local group = self.Group
	if group then group:CleanItems() end
end

function M:OpenCustom()
	self.OffsetLv = User.MapData.Level
	self:OpenTog()
	self:UpdateAction()
	self:UpdateLoad()
	if self.Tog1 then
		self:OnClickTog(self.Tog1)
	end
	self:AddEvent()
end

function M:CloseCustom()
	self:RemoveEvent()
end

function M:DisposeCustom()
	local group = self.Group
	if group then 
		group:Dispose()
		ObjPool.Add(self.Group)
	 end
	--TableTool.ClearDic(self)
end

return M

--endregion
