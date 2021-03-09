--region UIActivityBtnsView.lua
--Date
--此文件由[HS]创建生成

require("UI/UIMainMenu/UIActivityBtn")
require("UI/UIMainMenu/UIActivityMenus")
require("UI/UIMainMenu/UIActivityBaseBtns")
require("UI/UIMainMenu/UIActivityRightTopBtns")
require("UI/UIMainMenu/UIActivityRightCenterBtns")
require("UI/UIMainMenu/UIActivityLeftCenterBtns")
require("UI/UIMainMenu/UIActivityLeftBottomBtns")

UIActivityBtnsView = {}
local M = UIActivityBtnsView

local aMgr = ActivityMgr
local sMgr = SurverMgr
local oMgr = OpenMgr

M.IsOpen = false		--UI是否开启
M.IsDeploy = false		--按钮是否收缩 false-收缩 true-展开
M.IsBottomStatus = true
M.IsSpecial = false 	--是否是副本场景
M.IsPlayBottomBtn = false

--注册的事件回调函数

function M:New(parent, go)
	self.Parent = parent
	local name = "UI主界面活动窗口"
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.MiniMapZoomBtn = C(UIButton, trans, "ActivityZoomBtn", name, false)
	self.MiniMapZoomBG = T( trans, "ActivityZoomBtn/Background")
	self.ZoomAction = T(trans, "ActivityZoomBtn/Action")

	
	self.LB = T(trans, "LeftButtom")
	self.SBtn = T(trans,"LeftButtom/SystemBtn")
	self.SBAction = T(trans, "LeftButtom/SystemBtn/Action")
	self.PlayTween = C(UIPlayTween, trans, "LeftButtom/SystemBtn/Sprite", name, false)
	self.SBPanel = T(trans, "Bottom")
	self.SBBox = C(BoxCollider, trans, "Bottom/LeftButtom", name, false)
	
	self.BufferRoot = T(trans, "BufferRoot")				--缓存Items节点
	self.Prefab = T(trans, "BtnItem")						--预制Item
	self.BufferItems = {}									--缓存Items队列
	for i=1,50 do
		self:AddBufferItem(self.BufferItems)
	end

	self.RightTop = ObjPool.Get(UIActivityRightTopBtns)
	self.RightTop:Init(self, go)
	self.RightCenter = ObjPool.Get(UIActivityRightCenterBtns)
	self.RightCenter:Init(self, go)
	self.LeftCenter = ObjPool.Get(UIActivityLeftCenterBtns)
	self.LeftCenter:Init(self, go)
	self.LeftBottom = ObjPool.Get(UIActivityLeftBottomBtns)
	self.LeftBottom:Init(self, go)


	return M
end

function M:AddEvent()
	self.OnPlayTween= EventDelegate.Callback(self.OnPlayTweenFinished, self)
	EventDelegate.Add(self.PlayTween.onFinished, self.OnPlayTween)
	local E = UITool.SetLsnrSelf
	--控件事件
	if self.MiniMapZoomBtn then
		E(self.MiniMapZoomBtn, self.ClickRightTopBtn, self, nil, false)
	end
	if self.SBtn then
		E(self.SBtn, self.ClickSBtn, self)
	end
	if self.SBBox then
		E(self.SBBox, self.ClickSBtn, self, nil, false)
	end
	self:SetEvent("Add")
end

function M:RemoveEvent()
	EventDelegate.Remove(self.PlayTween.onFinished, self.OnPlayTween)
	self:SetEvent("Remove")
end

function M:SetEvent(fn)
	aMgr.eInit[fn](aMgr.eInit, self.InitData, self)
	aMgr.eOpen[fn](aMgr.eOpen, self.AddSystem, self)
	aMgr.eClose[fn](aMgr.eClose, self.RemoveSystem, self)
	oMgr.eShowActEff[fn](oMgr.eShowActEff, self.ShowActEff, self)
end

function M:OnPlayTweenFinished()
	self.IsPlayBottomBtn = false
end

--系统开启特效播放
function M:ShowActEff(data, go)
	if not data then return end
	if LuaTool.IsNull(go) == true then return end
	--[[
	local base = self.Parent
	if base then
		local hide = base.HideBtn
		hide.value = false
		base:ClickHideBtn()
	end
	]]--
	local temp = ActivityTemp[tostring(data.Temp.lvid)]
	if not temp then 
		Destroy(go)
		return 
	end
	local change = self:GetChange(temp)
	if change == false then
		local layer = temp.layer
		if layer >= 0 and layer <= 3 then
			local rightTop = self.RightTop
			if rightTop then rightTop:ShowActEff(temp, go) end
		elseif layer == 4 or layer == 5 then
			local rightCenter = self.RightCenter
			if rightCenter then rightCenter:ShowActEff(temp, go) end
		elseif layer == 6 then
			local leftCenter = self.LeftCenter
			if leftCenter then leftCenter:ShowActEff(temp, go) end
		elseif layer == 7 then
			local leftTop = self.LeftBottom
			if leftTop then leftTop:ShowActEff(temp, go) end
		end
	else
		local leftCenter = self.LeftCenter
		if leftCenter then leftCenter:ShowActEff(temp, go) end
	end
end

function M:ScreenChange(orient, init)
	local leftCenter = self.LeftCenter
	if leftCenter then leftCenter:ScreenChange(orient, init) end
end

function M:InitData(init)
	if not init then init = true end
	if init == true then
		local rightTop = self.RightTop
		if rightTop then rightTop:InitData() end
		local rightCenter = self.RightCenter
		if rightCenter then rightCenter:InitData() end
		local leftCenter = self.LeftCenter
		if leftCenter then leftCenter:InitData() end
		local leftBottom = self.LeftBottom
		if leftBottom then leftBottom:InitData() end
	end
	local action = self.ZoomAction
	if zAction then 
		zAction:SetActive(SystemMgr:GetActivityStatusForList({0,1,2,3}) == true and self.IsDeploy == false) 
	end
	local sbAction = self.SBAction
	if sbAction then 
		sbAction:SetActive(SystemMgr:GetActivityStatusForList({7}) == true and self.IsBottomStatus == true) 
	end
end

function M:AddSystem(temp, active)
	local target = nil
	if active == nil then
		active = true
	end
	local change = self:GetChange(temp)
	if change == false then
		local layer = temp.layer
		if layer >= 0 and layer <= 3 then
			local rightTop = self.RightTop
			if rightTop then rightTop:AddSystem(temp, active) end
			local action = self.ZoomAction
			if action then action:SetActive(SystemMgr:GetActivityStatusForList({0,1,2,3}) == true and self.IsDeploy == false) end
		elseif layer == 4 or layer == 5 then
			local rightCenter = self.RightCenter
			if rightCenter then rightCenter:AddSystem(temp, active) end
		elseif layer == 6 then
			local leftCenter = self.LeftCenter
			if leftCenter then 
				leftCenter:AddSystem(temp, active) 
				if leftCenter:ItemsCount() > 3 then
					leftCenter:BlackItem()
				end
			end
		elseif layer == 7 then
			local leftTop = self.LeftBottom
			if leftTop then leftTop:AddSystem(temp, active) end
			local action = self.SBAction
			if action then action:SetActive(SystemMgr:GetActivityStatusForList({7}) == true and self.IsBottomStatus == true) end
		end
	else
		local leftCenter = self.LeftCenter
		if leftCenter:ItemsCount() > 3 then
			local rightTop = self.RightTop
			if rightTop then 
				local status, pos = rightTop:CheckItem(temp.layer, temp.id)
				if statsu == true then
					rightTop:RemoveSystem(temp) 
				end
			end
		end
		if leftCenter then leftCenter:AddSystem(temp, active, change) end
	end
end

function M:RemoveSystem(temp)
	local layer = temp.layer
	local change = self:GetChangeRemove(temp)
	if change == false then
		if layer >= 0 and layer <= 3 then
			local rightTop = self.RightTop
			if rightTop then rightTop:RemoveSystem(temp) end
			local action = self.ZoomAction
			if action then action:SetActive(SystemMgr:GetActivityStatusForList({0,1,2,3}) == true and self.IsDeploy == false) end
		elseif layer == 4 or layer == 5 then
			local rightCenter = self.RightCenter
			if rightCenter then rightCenter:RemoveSystem(temp) end
		elseif layer == 6 then
			local leftCenter = self.LeftCenter
			if leftCenter then 
				leftCenter:RemoveSystem(temp) 
			end
		elseif layer == 7 then
			local leftTop = self.LeftBottom
			if leftTop then leftTop:RemoveSystem(temp) end
			local action = self.SBAction
			if action then action:SetActive(SystemMgr:GetActivityStatusForList({7}) == true and self.IsBottomStatus == true) end
		end
	else
		local leftCenter = self.LeftCenter
		if leftCenter then 
			leftCenter:RemoveSystem(temp, true) 
		end
	end
end

--[[[缓存item]]--
function M:AddBufferItem(items)
	local go = GameObject.Instantiate(self.Prefab)
	local data = ObjPool.Get(UIActivityBtn)
	data:Init(go)
	data.Base = self
	table.insert(items, data)
	data.Root.parent = self.BufferRoot.transform
end

function M:GetChange(temp)
	if not temp.change then return false end
	if temp.change >= 1 then
		local leftCenter = self.LeftCenter
		if leftCenter then 
			if leftCenter:IsExist(temp) == false then
				if leftCenter:ItemsCount() < 3 then
					return true
				end
			else 
				return true
			end
		end
	end
	return false
end

function M:IsExist(temp)
	if not temp.change then return false end
	if temp.change >= 1 then
		local leftCenter = self.LeftCenter
		if leftCenter then 
			if leftCenter:IsExist(temp) == true then
				return true
			end
		end
	end
	return false
end


function M:GetChangeRemove(temp)
	if not temp.change then return false end
	if temp.change >= 1 then
		local layer = temp.layer
		if layer >= 0 and layer <= 3 then
			local leftTop = self.RightTop
			if leftTop then return leftTop:IsExist(temp) == false end
		elseif layer == 4 or layer == 5 then
			local rightCenter = self.RightCenter
			if rightCenter then return rightCenter:IsExist(temp) == false end
		elseif layer == 7 then
			local leftTop = self.LeftBottom
			if leftTop then return leftTop:IsExist(temp) == false end
		end
	end
	return true
end

--从缓存获取item
function M:GetItem()
	local buffer = self.BufferItems
	local len = #buffer
	if len == 0 then 
		self:AddBufferItem(buffer)
		len = #buffer
	end
	local item = buffer[len]
	table.remove(buffer, len)
	return item
end

--将item压入缓存
function M:SetItem(item)
	if not item then return end
	local buffer = self.BufferItems
	if buffer then
		local root = self.BufferRoot
		if root then
			item.Root.parent = root.transform
		end
		table.insert(buffer, item)
	end
end 
--[[[缓存item]]--

function M:UpdateTween()
	self.IsPlayBottomBtn = false
	local value = SceneMgr:IsSpecial()
	if User.SceneId == MarryInfo.copyId then
		value = true
	end

	if value == nil then value = false end
	self.IsSpecial = value
	if value == nil then return end
	local rightTop = self.RightTop
	local rightCenter = self.RightCenter
	if rightTop then
		if value == true then
			rightTop:CustomPlayTween(value, true)
			self:UpdateAlphaStatus(not value, true)
		else
			rightTop:SpecialPlayTween(not value, true)
			self:UpdateAlphaStatus(value, true)
		end
	end
	local btn = self.SBtn
	if btn then
		local status = self.IsBottomStatus
		if status == false then
			local id = SceneMgr.Last
			if id ~= nil then
				if SceneMgr:IsCopy(id) == true or id == MarryInfo.copyId then
					self:ClickSBtn()
				end
			end
		end
	end
end

---------------------------------点击按钮-------------------------------------------

function M:UpdateBottomStatus(value)
	local leftBottom = self.LeftBottom
	if leftBottom then
		leftBottom:UpdateBottomStatus(value)
	end
end

--点击左上收纳按钮
function M:ClickRightTopBtn(go) 
	local bool = not self.IsDeploy
	UIMainMenu.eHide(self.IsDeploy)
	self:UpdateAlphaStatus(bool)
end

function M:UpdateAlphaStatus(bool, changeScene)	
	self.IsDeploy = bool
	local rightTop = self.RightTop
	local rightConter = self.RightCenter
	if self.IsSpecial == true then
		local rightCenter = self.RightCenter
		if rightTop then
			rightTop:SpecialPlayTween(bool, changeScene)
		end
		if rightCenter then
			rightCenter:SpecialPlayTween(bool, changeScene)
		end
	else
		if rightTop then
			rightTop:CustomPlayTween(bool, changeScene)
		end
	end
	local bg = self.MiniMapZoomBG
	if bg then
		local angle = bg.transform.localEulerAngles
		if bool == false then 
			angle.z = 0
		else
			angle.z = 180 
		end
		bg.transform.localEulerAngles = angle
	end
	local action = self.ZoomAction
	if action then action:SetActive(SystemMgr:GetActivityStatusForList({0,1,2,3}) == true and self.IsDeploy == false) end
end

function M:ClickSBtn(go)
	if self.Parent and self.Parent.gbj.activeSelf == false then
		return
	end
	if self.IsPlayBottomBtn == true then 
		return 
	end
	self.IsPlayBottomBtn = true
	local value = self.IsBottomStatus
	local parent = self.Parent
	local box = self.SBBox
	if box then box.enabled = value end
	if parent then parent:UpdateBottomStatus(value) end
	self:UpdateBottomStatus(not value)
	self.IsBottomStatus = not value
	local action = self.SBAction
	if action then action:SetActive(SystemMgr:GetActivityStatusForList({7}) == true and self.IsBottomStatus == true) end
	local playTween = self.PlayTween
	if playTween then 
		playTween:Play(value) 
	end
end

--更新红点状态
function M:UpdateAction(type, isAdd)
	local key,temp = aMgr:Find(type)
	if not temp then return end

	local layer = temp.layer
	if layer >= 0 and layer <= 3 then
		local rightTop = self.RightTop
		if rightTop then rightTop:UpdateAction(type, isAdd) end
	elseif layer == 4 or layer == 5 then
		local rightCenter = self.RightCenter
		if rightCenter then rightCenter:UpdateAction(type, isAdd) end
	elseif layer == 6 then
		local leftCenter = self.LeftCenter
		if leftCenter then leftCenter:UpdateAction(type, isAdd) end
	elseif layer == 7 then
		local leftTop = self.LeftBottom
		if leftTop then leftTop:UpdateAction(type, isAdd) end
	end

	if temp.change then
		if self.RightTop then self.RightTop:UpdateAction(type, isAdd) end
		if self.RightCenter then self.RightCenter:UpdateAction(type, isAdd) end
		if self.LeftCenter then self.LeftCenter:UpdateAction(type, isAdd) end
		if self.LeftBottom then self.LeftBottom:UpdateAction(type, isAdd) end
	end
end

function M:SetActive(value)
	if self.gameObject then
		self.gameObject:SetActive(value)
		if value == true then
			local rightTop = self.RightTop
			if rightTop then rightTop:RenovatePos() end
			local rightCenter = self.RightCenter
			if rightCenter then rightCenter:RenovatePos() end
			local leftCenter = self.LeftCenter
			if leftCenter then leftCenter:RenovatePos() end
			local leftBottom = self.LeftBottom
			if leftBottom then leftBottom:RenovatePos() end
		end
	end
end

function M:Open()
	self.IsOpen = true
	self:AddEvent()
	self:InitData(false)
	local rightTop = self.RightTop
	if rightTop then rightTop:Open() end
	local rightCenter = self.RightCenter
	if rightCenter then rightCenter:Open() end
	local leftCenter = self.LeftCenter
	if leftCenter then leftCenter:Open() end
	local leftBottom = self.LeftBottom
	if leftBottom then leftBottom:Open() end
end

function M:Close()
	self.IsOpen = false
	local rightTop = self.RightTop
	if rightTop then rightTop:Close() end
	local rightCenter = self.RightCenter
	if rightCenter then rightCenter:Close() end
	local leftCenter = self.LeftCenter
	if leftCenter then leftCenter:Close() end
	local leftBottom = self.LeftBottom
	if leftBottom then leftBottom:Close() end
end

function M:Update()
end

function M:Clear(isReconnect)
	local rightTop = self.RightTop
	if rightTop then rightTop:Clear() end
	local rightCenter = self.RightCenter
	if rightCenter then rightCenter:Clear() end
	local leftCenter = self.LeftCenter
	if leftCenter then leftCenter:Clear() end
	local leftBottom = self.LeftBottom
	if leftBottom then leftBottom:Clear() end

	self.IsDeploy = true
end

function M:Dispose()
	self:RemoveEvent()
	local rightTop = self.RightTop
	if rightTop then rightTop:Dispose() end
	local rightCenter = self.RightCenter
	if rightCenter then rightCenter:Dispose() end
	local leftCenter = self.LeftCenter
	if leftCenter then leftCenter:Dispose() end
	local leftBottom = self.LeftBottom
	if leftBottom then leftBottom:Dispose() end
end
--endregion
