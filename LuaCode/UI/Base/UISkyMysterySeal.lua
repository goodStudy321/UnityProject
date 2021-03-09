--region UISkyMysterySeal.lua
--Date
--此文件由[HS]创建生成
require("UI/UISkyMysteryseal/UISkyMysterySealOpen")
require("UI/UISkyMysteryseal/UISkyMysterySealProTipView")
require("UI/UISkyMysteryseal/UISkyMysterySealSuitItem")
require("UI/UISkyMysterySeal/UISkyMysterySealPreviewView")
require("UI/UISkyMysteryseal/UISkyMysterySealStrengthView")
require("UI/UISkyMysteryseal/UISkyMysterySealTip")
require("UI/UISkyMysteryseal/UISkyMysterySealTipView")
require("UI/UISkyMysteryseal/UISkyMysterySealDecomposeView")
require("UI/UISkyMysterySeal/UISkyMysterySealWarehouse")
require("UI/UISkyMysterySeal/UISkyMysterySealItem")
require("UI/UISkyMysterySeal/UISkyMysterySealShowView")

UISkyMysterySeal = UIBase:New{Name ="UISkyMysterySeal"}

local M = UISkyMysterySeal

function M:InitCustom()
	local name = "天机印"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.CloseBtn = T(trans, "Button")
	self.XQBtn = C(UIToggle, trans, "XQ", name, false)
	self.XQAction = T(trans, "XQ/Action")
	self.QHBtn = C(UIToggle, trans, "QH", name, false)
	self.QHAction = T(trans, "QH/Action")
	self.TFBtn = C(UIToggle, trans, "TF", name, false)

	self.Mask = T(trans,"Mask")
	self.OpenView = UISkyMysterySealOpen:New(T(trans, "OpenView"))
	self.ShowView = UISkyMysterySealShowView:New(T(trans, "ShowView"))
	self.ProTipView = UISkyMysterySealProTipView:New(T(trans, "ProTipView"))
	self.TipView = UISkyMysterySealTipView:New(T(trans, "TipView"))
	self.StrengthView= UISkyMysterySealStrengthView:New(T(trans, "StrengthView"))
	self.WarehouseView = UISkyMysterySealWarehouse:New()
	self.WarehouseView:Init(T(trans, "WarehouseView"))
	self.DecomposeView = UISkyMysterySealDecomposeView.New(T(trans, "DecomposeView"))
	self.DecomposeView:Init()
	self.PreviewView = UISkyMysterySealPreviewView:New(T(trans, "PreviewView"))

	self:BtnEvent()
end

--==============================--
--注册/移除 事件侦听
--==============================--
function M:BtnEvent()
	local E = UITool.SetLsnrSelf
	local S = EventDelegate.Add
	local CB = EventDelegate.Callback
	local close = self.CloseBtn
	local xq = self.XQBtn
	local qh = self.QHBtn
	local tf = self.TFBtn
	local mask = self.Mask
	if close then E(close, self.Close, self) end
	if xq then 
		S(xq.onChange, CB(self.SelectToggle, self))
		E(xq, self.OnClickTogBtn, self, nil, false)
	end
	if qh then 
		S(qh.onChange, CB(self.SelectToggle, self))
		E(qh, self.OnClickTogBtn, self, nil, false) 
	end
	if tf then 
		S(tf.onChange, CB(self.SelectToggle, self))
		E(tf, self.OnClickTogBtn, self, nil, false) 
	end
if mask then 
		E(mask, self.OnClickMask, self, nil, false) 
	end
end

function M:SetEvent(M)
end

function M:SetLuaEvent(fn)
	--FightVal.eChgFv[fn](FightVal.eChgFv, self.UpdateFight, self)
	SMSMgr.eOpenHold[fn](SMSMgr.eOpenHold, self.UpdateOpenHold, self)
	SMSMgr.eChangeHold[fn](SMSMgr.eChangeHold, self.UpdateHoldInfo, self)
	SMSMgr.eStrengthHold[fn](SMSMgr.eStrengthHold, self.UpdateHoldInfo, self)
	SMSMgr.eChangeConsume[fn](SMSMgr.eChangeConsume, self.UpdateConsum, self)
	SMSMgr.eChangeRed[fn](SMSMgr.eChangeRed, self.UpdateRedAction, self)
	--SMSMgr.eChangeSuitAceive[fn](SMSMgr.eChangeSuitAceive, self.ChangeSuitAceive, self)
	PropMgr.eMSMUpdate[fn](PropMgr.eMSMUpdate, self.UpdateProps, self)
	--cMgr.eUpdateSuccessListEnd[fn](cMgr.eUpdateSuccessListEnd, self.UpdateReward, self)
end

--==============================--
--调用
--==============================--
function M:SetShowSelect(index)
	local view = self.ShowView
	if not view then return end
	view:UpdateSelectIndex(index)
end

function M:SetWarehouseViewMenu(info)
	local view = self.WarehouseView
	if not view then return end
	view:SetMenu(info.OpenTemp.index)
end

--更新背包箭头
function M:UpdateWarehouseViewArr(info)
	local view = self.WarehouseView
	if not view then return end
	view:UpdateCellArr(info.OpenTemp.index)
end

--==============================--
--打开UI
--==============================--
--打开开孔界面
function M:ShowOpenView(info)
	local cur = UIToggle.current
	if cur then
		cur:Set(false, true, false)
	end
	local qh = self.XQBtn
	if qh then
		qh:Set(true, true, false)
	end
	self.WarehouseView:SetActive(false)
	self.ProTipView:SetActive(false)
	self.OpenView:UpdateInfoData(info)
	self.OpenView:SetActive(true)
end
--关闭开孔界面
function M:HideOpenView(showWV)
	if showWV == true then
		self.WarehouseView:SetActive(true)
		self.ProTipView:SetActive(true)
	end
	self.OpenView:SetActive(false)
end
--打开全属性显示tip
function M:ShowProTipView()
	self.ProTipView:UpdateData()
end
--打开背包分页
function M:ShowWarehouseView(info)
	local cur = UIToggle.current
	if cur then
		cur:Set(false, true, false)
	end
	local qh = self.XQBtn
	if qh then
		qh:Set(true, true, false)
	end
end
--打开tip
--target: true(背包，与当前镶嵌对比) false(当前镶嵌)
function M:ShowTipView(item, target)
	local tipView = self.TipView
	if not tipView then return end
	tipView:SetActive(false)
	tipView:UpdateData(item, target)
end

--打开强化
function M:ShowStrengthView(info)
	local cur = UIToggle.current
	if cur then
		cur:Set(false, true, false)
	end
	local qh = self.QHBtn
	if qh then
		qh:Set(true, true, false)
	end
	local view = self.StrengthView
	if not view then return end
	view:UpdateInfoData(info)
end

function M:UpdateStrengthView()
	local view = self.StrengthView
	if view then
		view:UpdateData()
	end
end

--打开分解
function M:UpdateDecomposeView()
	self:OnClickMask()
	local view = self.DecomposeView
	if view then
		view:SetActive(true)
	end 
end

--打开预览效果
function M:UpdatePreview(info)
	local view = self.ShowView
	if view then
		view:SetPage(SMSMgr.PageType.Yang)
		view:UpdatePreview(info)
	end
end

--==============================--
--事件
--==============================--
function M:SelectToggle()
	self:HideOpenView()
	local name = UIToggle.current.name
	if name == self.XQBtn.name and self.XQBtn.value == true then
		SMSMgr.CurToggle = 1
	elseif name == self.QHBtn.name and self.QHBtn.value == true then
		SMSMgr.CurToggle = 2
	elseif name == self.TFBtn.name and self.TFBtn.value == true then
		SMSMgr.CurToggle = 3
	end
end

function M:OnClickTogBtn(go)
	SMSControl:HideTipView()
	local name = go.name
	if name == self.XQBtn.name then
		self.ShowView:UpdateData()
	elseif name == self.QHBtn.name then
		local curIndex = SMSMgr.CurSelectIndex
		if curIndex ~= -1 then
			local infos = SMSMgr.Infos[SMSMgr.CurPage]
			local info = infos[curIndex]
			if info then
				if not info.Pro then
					self:ShowWarehouseView()
					UITip.Error("天机印孔未解锁")
					return
				elseif not info.Pro.Item then
					self:ShowWarehouseView()
					UITip.Error("天机印孔未镶嵌")
					return
				end
			end
		else
			UITip.Error("选择需要强化的天机印")
			self:ShowWarehouseView()
			return
		end
		self.ShowView:UpdateData()
		self.StrengthView:UpdateData()
	elseif name == self.TFBtn.name then
		self.PreviewView:UpdateData()
	end
end

function M:OnClickMask(go)
	self.TipView:SetActive(false)
end

--[[
--更新战斗力
function M:UpdateFight()
	local view = self.ShowView
	if not view then return end
	view:UpdateAllScoreLab()
end
]]--

--开孔返回
function M:UpdateOpenHold(info)
	self:HideOpenView()
	self.WarehouseView:SetActive(true)
	self.ProTipView:SetActive(true)
	self:SetWarehouseViewMenu(info)
	self:UpdateHoldInfo(info, true)
end

--更新
function M:UpdateHoldInfo(info, isOpen)
	local view = self.ShowView
	local tipView = self.TipView
	local proView = self.ProTipView
	if view then view:UpdateHoldInfo(info, isOpen) end
	if proView then proView:UpdateData() end
	--if tipView then tipView:UpdateHoldInfo(info) end
	if SMSMgr.CurToggle == 2 then
		local strengtView = self.StrengthView
		if strengtView then 
			strengtView:ShowEffect()
			strengtView:UpdateHoldInfo(info)
		end
	end
end

function M:ChangeSuitAceive()
	local view = self.ShowView
	if view then view:UpdateData() end
end

--更新强化销毁材料数量
function M:UpdateConsum()
	if SMSMgr.CurToggle == 2 then
		self.StrengthView:UpdateConsum()
	end
end

--分页红点
function M:UpdateRedAction()
	local xqStatus = SMSMgr.IsHole==true or SMSMgr.IsUpScore==true
	local qhStatus = SMSMgr.IsStrength
	self.XQAction:SetActive(xqStatus)
	self.QHAction:SetActive(qhStatus)
	self.ShowView:UpdateData()
	self.ProTipView:UpdateData()
	--self.ShowView:UpdateSAction()
end

--天机令道具消耗
function M:UpdateProps()
	if SMSMgr.CurToggle == 1 then
		self.WarehouseView:UpdateSelect()
		if self.DecomposeView:ActiveSelf() == true then
			self.DecomposeView:UpdateData()
		end
	end
end

--==============================--
--父类调用
--==============================--
function M:LateUpdate()
	local view = self.WarehouseView
	if view then
		view:LateUpdate()
	end
end

function M:OpenCustom()
	self:SetEvent(EventMgr.Add)
	self:SetLuaEvent("Add")
	--self.ShowView:UpdateData()
	self.WarehouseView:UpdateData()
	-- self.StrengthView:UpdateData()
	self:UpdateRedAction()
	self.ShowView:FirstClick()
	-- SMSNetwork:ReqInfoTos()
end

--自定义关闭
function M:CloseCustom()
    SMSMgr.CurPage = SMSMgr.PageType.Yang
	self:SetEvent(EventMgr.Remove)
	self:SetLuaEvent("Remove")
	local showView = self.ShowView
	local tipView = self.TipView
	local strengthView = self.StrengthView
	local warehouseView = self.WarehouseView
	local decomposeView = self.DecomposeView
	local previewView = self.PreviewView
	local proTipView = self.ProTipView
	if showView then showView:Reset() end
	if tipView then tipView:Reset() end
	if proTipView then proTipView:Reset() end
	if strengthView then strengthView:Reset() end
	if warehouseView then 
		warehouseView:CleanCells()
		warehouseView:SetActive(false) 
	end
	if decomposeView then 
		decomposeView:CleanCells()
		decomposeView:SetActive(false) 
	end
	if previewView then previewView:Reset() end
end

function M:OpenTabByIdx(t1, t2, t3, t4)
	-- body
end

function M:DisposeCustom()
	self.ShowView:Dispose()
	self.TipView:Dispose()
	self.StrengthView:Dispose()
	self.WarehouseView:Dispose()
	self.DecomposeView:Dispose()
	self.PreviewView:Dispose()
	JumpMgr.eOpenJump()
end

return M

