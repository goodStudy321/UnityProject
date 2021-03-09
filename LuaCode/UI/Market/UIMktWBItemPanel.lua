require("UI/Market/UIMktWantItem")

UIMktWBItemPanel = Super:New{Name = "UIMktWBItemPanel"}

local M = UIMktWBItemPanel

local iLog = iTrace.Log
local iError = iTrace.Error

function M:Init(panelObject)
    self.obj=panelObject
    self.objTrans=self.obj.transform

    local C = ComTool.Get
    local T = TransTool.FindChild

    self.item = T(self.objTrans, "ItemSV/Grid/Item_99")

    self.itemsSV = C(UIScrollView, self.objTrans, "ItemSV", tip, false)
    self.itemGrid = C(UIGrid, self.objTrans, "ItemSV/Grid", tip, false)

    self.OnNewData = EventHandler(self.ShowData, self);
    EventMgr.Add("NewClassNum", self.OnNewData);
    self.goodsList = nil
    self.items = {}

    self.delayResetCount = 0

end

function M:Open()
    self.obj:SetActive(true)
    self:ShowData()
end
function M:Close()
    self.obj:SetActive(false)
end

function M:Dispose()
    EventMgr.Remove("NewClassNum", self.OnNewData);
	TableTool.ClearDicToPool(self.items)
	TableTool.ClearDic(self.goodsList)
	self.delayResetCount = nil
end


--// 显示数据
function M:ShowData()

    local fstId = MarketMgr:GetSelFstId()
	local cfgList = MarketMgr:GetWBSecCfgByFstId(fstId)
	if cfgList == nil then
		self:RenewItemNum(0)
		return
	end
	
	self:RenewItemNum(#cfgList)
	for i = 1, #cfgList do
		self.items[i]:LinkAndConfig(cfgList[i], function() self:ClickSelItem(cfgList[i].id) end)
	end
end

--// 点击条目
function M:ClickSelItem(secId)
	MarketMgr:SetSelSecId(secId)
	MarketMgr:ResetFirstSearch()
	MarketMgr:ReqCurSearchItemInfo()

	self:Close();
	UIMktWBListPanel:Open();
end

--// 克隆商品条目
function M:CloneItem()
	local cloneObj = GameObject.Instantiate(self.item)
	cloneObj.transform.parent = self.item.transform.parent
	cloneObj.transform.localPosition = self.item.transform.localPosition
	cloneObj.transform.localRotation = self.item.transform.localRotation
	cloneObj.transform.localScale = self.item.transform.localScale
	cloneObj:SetActive(true)

	local cloneItem = ObjPool.Get(UIMktWantItem)
	cloneItem:Init(cloneObj)

	local newName = ""
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.item.name, "99", tostring(#self.items + 1))
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.item.name, "99", "0"..tostring(#self.items + 1))
	else
		newName = string.gsub(self.item.name, "99", "00"..tostring(#self.items + 1))
	end
	cloneObj.name = newName;

	self.items[#self.items + 1] = cloneItem;

	return cloneItem
end

--// 重置条目数量
function M:RenewItemNum(number)
	for a = 1, #self.items do
		self.items[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #self.items then
		for a = 1, realNum do
			self.items[a]:Show(true)
		end
	else
		for a = 1, #self.items do
			self.items[a]:Show(true)
		end

		local needNum = realNum - #self.items
		for a = 1, needNum do
			self:CloneItem()
		end
	end

	self.itemGrid:Reposition()
	self:DelayResetSVPosition()
end

--// 延迟重置滑动面板位置
function M:DelayResetSVPosition()
	self.delayResetCount = 2
end

return M