--region UIFlowers.lua
--Date
--此文件由[HS]创建生成

UIFlowersSend = {}
local M = UIFlowersSend

local fMgr = FriendMgr

M.base = nil
M.TargetInfo = nil
M.Item = nil

function M:New(root)
	self.root = root
	local name = "可操作提示面板"
	local trans = self.root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Cell = ObjPool.Get(UIItemCell)
	self.Cell:Init(T(trans, "ItemCell"))
	self.NameMenu = ObjPool.Get(UIFlowersSelectPlay)
	self.NameMenu:Init(T(trans, "NameMenu"))
	self.ItemMenu = ObjPool.Get(UIFlowersSelectType)
	self.ItemMenu:Init(T(trans, "ItemMenu"))
	self.ItemMenu:UpdateData()
	self.Page = ObjPool.Get(UIPageCount)
	self.Page:Init(T(trans, "Page"))
	self.Des = C(UILabel, trans, "Des", name, false)
	self.Btn = C(UIButton, trans, "Button", name, false)
	self.Toggle = C(UIToggle, trans, "Toggle", name, false)
	self.Tip =T(trans, "Tip")
	self.TipV = T(trans, "TipV")
	self:AddEvent()
	return M
end

function M:AddEvent()
	local S = UITool.SetLsnrSelf
	S(self.Btn.gameObject, self.OnClickBtn, self)
	S(self.Tip, self.OnClickTip, self)
	S(self.TipV, self.OnClickTipV, self, nil, false)

	self:SetDelegate(EventDelegate.Add)
	self:SetEvent("Add")
end

function M:RemoveEvent()
	self:SetDelegate(EventDelegate.Remove)
	self:SetEvent("Remove")
end

function M:SetDelegate(E)
end

function  M:SetEvent(fn)
	local page = self.Page
	if page then
		page.eCountChange[fn](page.eCountChange, self.CountChange, self)
	end
	local nMenu = self.NameMenu
	if nMenu then
		nMenu.eSelect[fn](nMenu.eSelect, self.OnNMenuChange, self)
	end
	local iMenu = self.ItemMenu
	if iMenu then
		iMenu.eSelect[fn](iMenu.eSelect, self.OnIMenuChange, self)
	end
	PropMgr.eUpdate[fn](PropMgr.eUpdate, self.UpdateItemList, self)
end

function M:UpdateData()
	self:Clean()
	local menu = self.NameMenu
	if menu then
		menu:UpdateData()
		menu:CustomSetValue(FlowersMgr.FriendID)
	end
	self.ItemMenu:CustomSetValue(1)

end

function M:UpdateCell()
	local item = self.Item
	if not item then return end
	if self.Cell then
		self.Cell:Clean()
		self.Cell:UpData(item)
		self.Cell:UpLab(item.name, true)
	end
end

function M:UpdateDes()
	local player = self.TargetInfo
	local pId = 0
	local pName = ""
	local iName = ""
	local count = 0
	local value = 0
	local v = 0
	if player then
		pId = player.ID
		pName = player.Name
	end
	if self.Item then
		iName = self.Item.name
		value = self.Item.uFxArg[1]
	end
	if self.Page then
		count = self.Page.Count
		if count == nil then count = 0 end
		v = value * count
	end
	if self.base and self.IsTip == nil then
		self.base:SetSendInfo(pId, pName, iName, count, v)
	end
	if self.Des then
		self.Des.text = string.format("[581F2A]您与[88F8FF]%s[-]可获得[88F8FF]%s[-]点魅力值若是好友可增加[88F8FF]%s[-]点亲密度[-]", pName, v, v)
	end
end

function M:OnClickBtn(go)
	local player = self.TargetInfo
	local item = self.Item
	local count = 0 
	if self.Page then
		count = self.Page.Count
	end
	if not player then
		UITip.Error("请先选择送花的对象")
		return
	end
	if not item then 
		UITip.Error("请选择要送的花的种类")
		return
	end
	if not count or count == 0 then
		UITip.Error("请选择要送送花的数量")
		return
	end
	local num = ItemTool.GetNum(item.id)
	if num < count then
		if StoreMgr.IsCanBuy(item.id) == true then	
			StoreMgr.TypeIdBuy(item.id, count - num, true)
		else
			UITip.Error(string.format( "拥有的[%s]的数量不足%s", item.name, count))
		end
		return
	end
	if player.ID == nil then
		UITip.Error("玩家不存在")
		return ;
	end
	FlowersMgr:ReqFlowerSend(player.ID, item.id, count, self.Toggle.value)
end

function M:OnClickTip()
	if self.TipV then self.TipV:SetActive(true) end
end

function M:OnClickTipV()
	if self.TipV then self.TipV:SetActive(false) end
end

function M:OnNMenuChange()
	local menu = self.NameMenu
	if menu then 
		local data = menu.Data
		if data then
			self.TargetInfo = data
		end
	end
	self:UpdateDes()
end

function M:OnIMenuChange()
	local menu = self.ItemMenu
	if menu then 
		local data = menu.Data
		if not data then return end
		local status = true
		if self.Item and self.Item.id ~= data.id then
			status = false
		end
		self.Item = data
		self:UpdateCell()
		if status == false then			
			self:CountChange()
		end
	end

	self:UpdateDes()
end

function M:UpdateItemList()
	if self.ItemMenu then
		self.ItemMenu:UpdateItemList()
	end
end

function M:CountChange()
	local page = self.Page
	if not page then return end
	local item = self.Item
	if not item then
		if self.IsTip == nil or self.IsTip == true then
			UITip.Error("请选择要送的花的种类")
			page:SetCount(0)
		end
		return
	end
	local num = ItemTool.GetNum(item.id)
	if not num then return end
	local count = 0
	if page and page.Count == nil then count = page.Count end
	if count > num then
		UITip.Error(string.format("送[%s]的数量大于拥有的数量", item.name))
		page:SetCount(num)
	end
	self:UpdateDes()
end

function M:SetActive(value, isTip)
	if self.root then 
		if value == true then
			self:UpdateData()
		else
			self:Clean(isTip)
		end
		self.root:SetActive(value) 
	end
end

function M:Clean(isTip)
	self.IsTip = isTip
	self.TargetInfo = nil
	self.Item = nil
	if self.Cell then
		self.Cell:Clean()
	end
	if self.NameMenu then
		self.NameMenu:Clean()
	end
	if self.ItemMenu then
		self.ItemMenu:Reset()
	end
	if self.Page then
		self.Page:Reset()
	end
end

function M:Dispose()
	self:Clean(false)
	self:RemoveEvent()
	if self.Cell then
		self.Cell:Destroy()
		ObjPool.Add(cell)
	end
	if self.Page then self.Page:Dispose() end
	self.Page = nil
	self.Cell = nil
	self.NameMenu = nil
	self.ItemMenu = nil
	self.Btn = nil
end
--endregion
