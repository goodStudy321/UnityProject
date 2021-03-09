--region UIMissionItem.lua
--任务面板 任务条目基类
--此文件由[HS]创建生成
UIMissionItem = Super:New{Name="UIMissionItem"}
local I = UIMissionItem
local BoxCollider = UnityEngine.BoxCollider

--构造函数
function I:Init(go)
	--变量
	self.gameObject = go
	--控件
	self.trans = self.gameObject.transform
	local name = string.format("UIMissionItem %s", self.gameObject.name)
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.trans
	self.Bg =  self.gameObject:GetComponent("UISprite")
	self.Box = self.gameObject:GetComponent("BoxCollider")
	self.MenuTip = self.gameObject:GetComponent("UIMenuTip")
	self.MoveRoot = T(trans, "MoveRoot")
	self.Type = C(UISprite,trans,"MoveRoot/Type",name,false)
	self.Title = C(UILabel,trans,"MoveRoot/Title",name,false)
	self.Status = C(UISprite,trans,"MoveRoot/Status",name,false)
	self.Value = C(UILabel,trans,"MoveRoot/Value",name,false)
	self.FlyBtn = T(trans, "MoveRoot/Fly")
	self.Prefab = T(trans,"MoveRoot/AutoPoint")

	--压入卡等级引导
	self.MenuTip:Clear()
	local items = self.MenuTip.items
	local list = MissGuideTemp
	for i=1,#list do
		local temp = list[i]
		if temp then 
			items:Add(temp.des)
		end
	end

	self.Height = 0
	--self.MenuTip.items = self.Tips
	--self.OnClickMenuTipAction = EventHandler(MissionMgr.ClickMenuTip, MissionMgr)
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTip, self)
	UITool.SetLsnrSelf(self.FlyBtn, self.ClickFlyBtn, self)
	EventMgr.Add("ClickMenuTipAction", self.OnClickMenuTipAction)
    --euiclose:Add(self.CloseUI,self)
	--[[
	UIEventListener.Get(self.FlyBtn).onClick = function(gameobject) 
		self:ClickFlyBtn(gameobject)  
	end
	]]--
end

function I:ClickFlyBtn(go)
	if Hangup:IsPause() == true then	
		Hangup:Resume(OpenMgr.FlyIconPause)
		MissionMgr:Execute(false)
	end
	if MissionMgr.Escort ~= nil then
		UITip.Error("请先完成护送任务")
		return 
	end
	local vip = VIPMgr.GetVIPLv() > 0
	local item = PropMgr.TypeIdByNum(31015) > 0
	local t = false
	if vip == true or item == true then
		t = true
	end

	if t == false then
		--MsgBox.ShowYes("小飞鞋使用条件不足（Vip等级不足或小飞鞋道具不足）");
		MapMgr:ShowFlyShoesMsg();
		return;
	end
	local miss = self.Mission
	Hangup:ClearAutoInfo()
	User:ResetMisTarID()
	MissionMgr:Execute(true)
	Hangup:SetAutoHangup(true)

	self:AutoExecuteAction(true)
end

function I:ChangeLv()
	if not self.MenuTip then return end
	local mission = self.Mission
	if not mission then return end
	local bool = mission:CheckLevel()
	local isCount = true
	if bool == true then
		local indexs = self.MenuTip.customIndex
		indexs:Clear()
		local list = MissGuideTemp
		for i=1,#list do
			local temp = list[i]
			if temp and User.MapData.Level >= temp.openlv then
				indexs:Add(i - 1) 
			end
		end
		isCount = indexs.Count > 0
	end
	--if  self.MenuTip.IsEnabled == false and MissionMgr.MissionMenu == false then
	--local enabled = mission.Temp.type == MissionType.Main and bool and isCount and MissionMgr.MissionMenu == false
	--if  self.MenuTip.IsEnabled == false then
		local enabled =  mission.Temp and mission.Temp.type == MissionType.Main and bool and isCount
		self:UpdateMenuTipStatus(enabled)
		--if enabled == true then MissionMgr.MissionMenu = true end
	--end
end

function I:IsShowMenuTip()
	local menu = self.MenuTip
	if menu then return menu.IsEnabled == true end
	return false
end

function I:UpdateMenuTipStatus(value)
	self.MenuTip.IsEnabled = value
end

function I:ClickMenuTip(name, tt, str, index)
	if not tt or tt ~= MenuType.Mission then return end
	local menus = self.MenuTip.items
	if not menus then return end
	local index = menus:IndexOf(str)
	MissionMgr:ClickMenuTip(index)
end

--更新任务数据
function I:UpdateData(mission)
	if not mission then return end
	if self.trans then self.trans.name = mission.Key end
	self.Mission = mission
	local temp = mission.Temp
	if not temp then 
		iTrace.eError("hs", "任务配置文件为nil")
		return 
	end
	self:ChangeLv()
	self:UpdateFlyStatus()
	self:UpdateMenus()
	--[[
	if self.FlyBtn then
		local value = temp.tarType ~= MTType.FlowChart and tree == nil
		self.FlyBtn:SetActive(value)
	end
	]]--
	--[[
	local chapter = ""
	if temp.type == MissionType.Main then
		local c = temp.chapter % 100
		chapter =  string.format("第%s章 ",c)
	end
	]]--
	local icon = ""
	local tp=temp.type
	if tp==MissionType.Liveness then tp=MissionType.Turn end
	if temp.childType then
		icon = string.format("miss_%s_%s", tp, temp.childType)
	else
		icon = string.format("miss_%s", tp)
	end
	self.Type.spriteName = icon
	--self.Title.text = string.format("%s%s",chapter,self:GetTitle(self.Mission))
 	self.Title.text = self:GetTitle(self.Mission)
	self:UpdateDes()
	local missionStatus = false
	if self.Mission.Status == MStatus.ALLOW_SUBMIT then
		missionStatus = true
		if MissionMgr:AutoTalk(self.Mission) == true then
			local ui = UIMgr.Dic[UIMainMenu.Name]
			if ui and ui.active == 1 then
				self:AutoExecuteAction(true)
			end
		end
	end
	self.Status.gameObject:SetActive(missionStatus)
	local curType =  MissionMgr.CurExecuteType
	if temp.lv > User.MapData.Level and curType and temp.type ~= curType then 
		--self:AutoExecuteAction(false) 
	end 
	self:UpdateHeight()
end

function I:UpdateFlyStatus()
	local mission = self.Mission
	if not mission then return end
	local value = mission:IsFly()
	if self.FlyBtn then
		self.FlyBtn:SetActive(value)
	end
	self:UpdateMoveRoot(value)
end

function I:UpdateMoveRoot(value)
	local root = self.MoveRoot
	if not root then return end
	local pos = Vector3.zero
	if value == false then
		pos = Vector3.New(-58, 0, 0)
	end
	root.transform.localPosition = pos
end

function I:UpdateMenus()
	local mission = self.Mission
	if not mission then return end
	local target = mission:GetCurTarget()
	if not target then return end
	local t = target.Temp.tarType
	if t ~= MTType.Item then return end
end

function I:UpdateDes()
	if not self.Value then return end
	if self.Mission == nil then return end
	self.Value.text = self.Mission:GetTargetDes("42db70")
end

function I:UpdateHeight()
	local height = self:GetHeight()
	self.Bg.height = height
	self.Box.center = Vector3.New(0,-height / 2,0)
	self.Box.size = Vector3.New(self.Box.size.x, height, 0)
end

function I:ClickAutoExecuteAction( ... )
	-- body
end

--执行任务事件
function I:AutoExecuteAction(value, changeExecute)
	local mission = self.Mission
	if mission then 
		if MissionTool:IsMainMissScene(self.Mission) == false then 
			if mission.Temp then
				SceneMgr:ReqPreEnter(mission.Temp.screen, true, true)
				return
			end
		end
		if mission:NotAllowExecute() == true then
			return
		end
		local temp = mission.Temp
		if mission:CheckLevel() == true then return end
		if mission.Status == MStatus.COMPLETE then return end
		if temp.type ~= MissionType.Feeder or mission.Status ~= MStatus.ALLOW_SUBMIT then
		  	MissionMgr:UpdateCurMission(mission)
		end
		if mission == nil then return end
		mission:AutoExecuteAction(MExecute.ClickItem, value, changeExecute) 
	end
end

--获取任务标题
function I:GetTitle(mission)
	local mType = MissionType
	local title = mission.Temp.name
	--title = string.format("%s{%s}",title,mission.ID)
	local t = self.Mission.Temp.type
	if (t == mType.Turn or t == mType.Family or t == mType.Escort) and t ~= mType.Liveness then
		local succ = self.Mission.Succ % self.Mission.Temp.ring
		local ring = self.Mission.Temp.ring
		if t ~= mType.Escort then 
			if succ == 0 then
				succ = self.Mission.Temp.ring
			end
		elseif t == mType.Escort then 
			ring = 3
			succ = ring - EscortMgr.Num
		end
		return string.format("%s (%s/%s)",title, succ, ring)
	end
	return title
end

--获取Item高度
function I:GetHeight()
	self.Height = 0
	if self.Value then
		self.Height = Mathf.Abs(self.Value.gameObject.transform.localPosition.y - self.Value.height - 15)
	end
	if self.Mission and self.Mission.Temp then
		if self.Mission.Temp.lv > User.MapData.Level then self.Height = self.Height + self:GetAutoPoint() end
	end
	if self.Box then
		self.Box.center = Vector3.New(0, - self.Height / 2, 0)
		if self.Bg then
			self.Box.size = Vector3.New(self.Bg.width, self.Height, 0)
		end
	end
	return self.Height 
end

function I:SetActive(value)
	local go = self.gameObject
	if go then
		go:SetActive(value)
		if value == false then self:Clear() end
	end
end

--获取挂机点坐标
function I:GetAutoPoint()
	return 0
end

function I:UpdatePos(value)
	if not self.trans then return end
	self.trans.localPosition = Vector3.up * value * -1
end

function I:CloseUI(uiName)
	if uiName ~= UIMenuTip.Name then
		return 
	end
	local mission = self.Mission
	if mission then
		local tip = self.MenuTip
		if tip and tip.IsEnabled == true then
			if mission.Temp.type == MissionType.Main then
				local ui = UIMgr.Dic[uiName]
				if ui then
				if LuaTool.Length(ui.Items) == 0 then return end
				end
				MissionMgr.MissionMenu = false
				self:UpdateMenuTipStatus(false)
			end
		end
	end
end

function I:Clear()
	self:UpdateMenuTipStatus(false)
	if self.trans then self.trans.name = "99999999" end
	self.Mission = nil
end

--销毁释放
function I:Dispose()
	self:UpdateMenuTipStatus(false)
	if self.gameObject then
		self.gameObject.transform.parent = nil
	end
	EventMgr.Remove("ClickMenuTipAction", self.OnClickMenuTipAction)
    --euiclose:Remove(self.CloseUI,self);
	self.OnClickMenuTipAction = nil
	self.Height = nil
	self.trans = nil

	self.Bg =  nil
	self.Box = nil
	self.Chapter = nil
	self.Title = nil
	self.Status = nil
	self.Value = nil
	self.Prefab = nil
	self.Mission = nil

	GameObject.Destroy(self.gameObject)
	self.gameObject = nil
end
--endregion
