--region UICopy.lua
--Date
--此文件由[HS]创建生成
require("UI/UICell/UICellEquipCopyItem")
require("UI/UICell/UICellCopyItem")
require("UI/UICopy/UICopyView")
require("UI/UICopy/UIEquipCopyView")
require("UI/UICopy/UICopyRect")
UICopy = UIBase:New{Name ="UICopy"}
local M = UICopy
local cMgr = CopyMgr
local tMgr = TeamMgr
--注册的事件回调函数

M.togList = {}

function M:InitCustom()
	local name = "副本选择面板"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild
	local SC = UITool.SetLsnrSelf

	

	local root = TransTool.Find(trans, "ToggleGroup")
	for i=1,2 do
		local tog = ObjPool.Get(BaseToggle)
		-- local tog = C(UIToggle, root, tostring(i) ,name, false)
		-- SC(tog, self.OnChgTog, self)
		-- self["RedPoint"..i] = T(tog.transform, "RedPoint") 
		-- table.insert(self.togList, tog)
		tog:Init(T( root, tostring(i)))
		tog.eClick:Add(self.OnChgTog, self)
		table.insert(self.togList, tog)
	end
	self.CopyView = ObjPool.Get(UICopyView)
	self.CopyView:Init(T(trans, "CopyView"))
	
	self.EquipView = ObjPool.Get(UIEquipCopyView)
	self.EquipView:Init(T(trans, "EquipView"))
	self.EquipView.eClose:Add(self.Close, self)
	UITool.SetLsnrClick(trans, "btn/BtnClose", name, self.CloseBtn, self)

	self:SetPage(self.copyType or CopyType.Exp)
	self:SetEvent("Add")
	self:InitRedPoint()
end


function M:SetEvent(fn)
	cMgr.eUpdateCopyCleanReward[fn](cMgr.eUpdateCopyCleanReward, self.UpdateCopyCleanReward, self)
	cMgr.eUpdateCopyData[fn](cMgr.eUpdateCopyData, self.UpdateCopyData, self)
	cMgr.eUpdateCopyStar[fn](cMgr.eUpdateCopyStar, self.UpdateCopyStar, self)
	cMgr.eUpdateCopyExpGuideTimes[fn](cMgr.eUpdateCopyExpGuideTimes, self.UpdateCopyExpGuideTimes, self)
	tMgr.eUpdateMatchStatus[fn](tMgr.eUpdateMatchStatus, self.UpdateBtnStatus, self)
	UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.UpdateUserLv, self)
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.BagUpdate, self)
	cMgr.eUpdateRedPoint[fn](cMgr.eUpdateRedPoint, self.UpdateRedPoint, self)
	TeamMgr.eCreateTeamSuccess[fn](TeamMgr.eCreateTeamSuccess, self.CreateTeamSuccess, self)
	PropMgr.eRemove[fn](PropMgr.eRemove, self.BagRemove, self)
	StoreMgr.eBuyResp[fn](StoreMgr.eBuyResp, self.BuyResp, self)
end


function M:CreateTeamSuccess()
	-- UIMgr.Open(UIMyTeam.Name)
	TeamMgr.CurCopyId = self.EquipView.Temp.id
	UIMgr.Open(UIMyTeam.Name,M.CreateTeamCb)
end

function M.CreateTeamCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:OnCopyEnter()
	end	
end

function M:OnChgTog(name)
	local index = tonumber(name)
	self:SwitchTog(index)
end

function M:SwitchTog(index)
	if self.index then 
		if self.index == index then
			return 
		else
			self.togList[self.index]:SetHighlight(false)
		end
	end

	if self.curView then
		self.curView:Close()
	end
	self.index = index
	if index == 1 then	
		self.curView = self.CopyView
	elseif index == 2 then
		local lv = CopyTemp["20201"].lv
		if User.MapData.Level < lv then
			self.index = 1
			self.curView = self.CopyView
			UITip.Log(string.format("达到%s级开放", UIMisc.GetLv(lv)))
		else
			self.curView = self.EquipView
		end
	end
	self.togList[self.index]:SetHighlight(true)
	if self.curView then
		self.curView:Open()
	end
end

function M:InitRedPoint()
	cMgr:UpdateCopyRedPoint()
end

function M:UpdateRedPoint(copyType, state)
	if copyType == cMgr.Exp
	or copyType == cMgr.Glod
	or copyType == cMgr.STD
	or copyType == cMgr.XH
	or copyType == cMgr.ZLT
	then
		self.CopyView:UpdateRedPoint(copyType, state)
		self.togList[1]:SetRedPoint(self.CopyView:GetAllRedPointState())
	elseif copyType == cMgr.Equip then
		self.togList[2]:SetRedPoint(state)
	end
end


function M:BagUpdate()
	if self.CopyView and self.CopyView.Rect then
		self.CopyView.Rect:BagUpdate()
	end
end

function M:BagRemove(id,tp,type_id,action)
	if action == 20002 and type_id == 31025 then  
		if self.CopyView and self.CopyView.Rect then
			UITip.Log("增加副本次数1次")
			self.CopyView.Rect:UpdateBtnNum()
		end
	end
end

function M:BuyResp(typeId)
	if self.CopyView and self.CopyView.Rect then
		self.CopyView.Rect:BuyResp(typeId)
	end
end


function M:SetPage(copyType)
	if not copyType then return end
	if copyType == CopyType.Exp or copyType == CopyType.Glod or copyType == CopyType.SingleTD or copyType == CopyType.XH  or copyType == CopyType.ZLT then
		self.CopyView:CustomOpen(copyType)
		self:SwitchTog(1)
	elseif copyType == CopyType.Equip then
		self:SwitchTog(2)
	end
end

function M:Show(copyType)
	self.copyType = copyType
	UIMgr.Open(self.Name, self.OpenCb, self)
end

function M:OpenTabByIdx(t1, t2, t3, t4)
	self:SetPage(t1)
end


function M:OpenCb(name)
	self:SetPage(self.copyType)
end


function M:UpdateCopyData(t)
	if self.CopyView and self.CopyView:IsActive() then self.CopyView:UpdateCopyData(t) end
	if self.EquipView and self.EquipView:IsActive() then self.EquipView:UpdateCopyData() end
end

function M:UpdateCopyStar(t,id)
	if self.CopyView then self.CopyView:UpdateCopyData(t) end
end

function M:UpdateCopyExpGuideTimes()
	if self.CopyView and self.CopyView:IsActive() then  self.CopyView:UpdateCopyExpGuideTimes() end
end

function M:UpdateBtnStatus()
	if self.EquipView then self.EquipView:UpdateBtnStatus() end
end

function M:UpdateUserLv()
	if self.CopyView and self.CopyView:IsActive() then  self.CopyView:UpdateUserLv() end
	if self.EquipView and self.EquipView:IsActive() then self.EquipView:UpdateUserLv() end
end

function M:UpdateCopyCleanReward()
	UIMgr.Open(UIGetRewardPanel.Name, self.UpdateGetRewardData, self)
	if self.CopyView and self.CopyView.Rect then
		self.CopyView.Rect:UpdateCleanCopy()
	end
end

function M:UpdateGetRewardData(name)
	local ui = UIMgr.Dic[name]
	if ui then
		local rewards = cMgr.CopyCleanRewards
		local list = nil
		if rewards then
			list = {}
			for i,v in ipairs(rewards) do
				local data = {}
				data.k = v.k
				data.v = v.v
				data.b = false
				table.insert(list,data)
			end
		end
		if not list then ui:Close() return end
		ui:UpdateData(list)
	end
end


function M:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end


function M:DisposeCustom()
	self:SetEvent("Remove")
	if self.CopyView then
		ObjPool.Add(self.CopyView)
	end
	if self.EquipView then
		self.EquipView.eClose:Remove(self.Close, self)
		ObjPool.Add(self.EquipView)
	end
	self.CopyView = nil
	self.EquipView = nil
	TableTool.ClearDicToPool(self.togList)
	self.curView = nil
	self.index = nil
	self.copyType = nil
end

return M

--endregion
