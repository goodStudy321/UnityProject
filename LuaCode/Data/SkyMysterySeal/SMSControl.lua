--region 
--
--此文件由[HS]创建生成

SMSControl = {Name = "SMSControl"}
local M = SMSControl

--==============================--
--desc:打开UI
--==============================--
--打开开孔界面
function M:ShowOpenView(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:ShowOpenView(info)
end

function M:HideOpenView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:HideOpenView(true)
end

--打开全属性显示tip
function M:ShowProTipView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:ShowProTipView()
end
--打开背包
function M:ShowWarehouseView(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:ShowWarehouseView(info)
	-- body
end
--打开强化窗口
function M:ShowStrengthView(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:ShowStrengthView(info)
end
--打开分解窗口
function M:ShowDecomposeView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:UpdateDecomposeView()
end
--打开tip
--target: true(背包，与当前镶嵌对比) false(当前镶嵌)
function M:ShowTipView(item, target)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:ShowTipView(item, target)
end
--关闭UI
function M:HideTipView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:OnClickMask()
end
--打开预览
function M:ShowPreview(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:UpdatePreview(info)
end
--打开道具tip
function M:ShowItemTip(item)
	self.ItemTipData = item
	UIMgr.Open(PropTip.Name,self.OpenCb,self)
end
function M:OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
		ui:UpData(self.ItemTipData,self.isCompare,nil,self.attWhat,self.isSpir)	
	end
end
--打开副本UI
function M:OpenCopyUI()
	UIRobbery:OpenRobbery(11)
end
--打开获取途径
function M:OpenGetWay(pos)
	local data = SMSMgr.GetWay
	pos = Vector3.zero
	GetWayFunc.GetWay(SMSMgr.GetWayID, pos)
end
--==============================--
--desc:更新UI
--==============================---
function M:UpdateStrengthView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:UpdateStrengthView()
end
--设置选中孔
function M:SetShowViewSelect(index)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:SetShowSelect(index)
end
--设置背包筛选
function M:SetWarehouseViewMenu(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:SetWarehouseViewMenu(info)
end
--更新背包箭头
function M:UpdateWarehouseViewArr(info)
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	ui:UpdateWarehouseViewArr(info)
end
--清除TipView
function M:ResetTipView()
	local ui = UIMgr.Dic[UISkyMysterySeal.Name]
	if not ui then return end
	local view = ui.TipView
	if view then view:Reset() end
end
--==============================--
--desc:操作
--==============================---
--操作孔
function M:HoldControl(type, id, itemid, t)
	self.ControlType = type
	self.ControlID = id
	self.ControlItemID = itemid
	self.controlT = t
	MsgBox.ShowYes("此操作会让强化等级与战力下降\n确定要继续操作吗？",
	self.OnConrolCB, 
	self, 
	"确定")
end

function M:OnConrolCB()
	SMSNetwork:ReqPlaceOperateTos(self.ControlType, self.ControlID, self.ControlItemID, self.controlT)
end

return M