
--[[
	每日限购
]]

require("UI/UILvLimitBuy/UILvLimitBuyItem")

UILvLimitBuyWnd = UIBase:New{Name="UILvLimitBuyWnd"};

local M=UILvLimitBuyWnd

local iLog = iTrace.Log
local iError = iTrace.Error

local US = UITool.SetLsnrClick
local USS = UITool.SetLsnrSelf

--//初始化界面
function M:InitCustom()
	local C = ComTool.Get
	local T = TransTool.FindChild
	local TF = TransTool.Find

	local root = self.root

	local trans = T(root,"WndContainer").transform

	US(trans, "CloseBtn", "", self.Close, self)
	self.itemGrid = C(UIGrid,trans,"BuyPage/BuyPanelSV/UIGrid",tip,false)
	self.grid = self.itemGrid.gameObject
	self.item = T(self.grid.transform,"BuyItem_99")
	--self.que = T(trans,"quePage")
	
	--self.sel = C(UIToggle,self.que.transform,"sel",tip,false)
	--USS(self.sel.transform,self.OnTog,self)
	-- US(self.que.transform,"yesBtn","",self.Que,self)
	-- US(self.que.transform,"noBtn","",self.Quit,self)
	-- US(self.que.transform,"CloseBtn","",self.Que,self)
	self.items = {}

	--self.timeLb = C(UILabel,trans,"RestLab",tip,false)
	self:SetLsnr("Add")
end

function M:SetLsnr(key)
	PropMgr.eGetAdd[key](PropMgr.eGetAdd, self.OnAdd, self)
	--LvLimitBuyMgr.eUpdateTime[key](LvLimitBuyMgr.eUpdateTime, self.UpdateTime, self)
	LvLimitBuyMgr.eUpdate[key](LvLimitBuyMgr.eUpdate, self.ShowData, self)
end

function M:OnRemoveSelf()

end

-- function M:UpdateTime(time)
-- 	self.timeLb.text = DateTool.FmtSec(time,0,0)
-- end

-- function M:CloseClick()
-- 	local status = LvLimitBuyMgr:GetStatus()
-- 	if status == 1 then
-- 		self.que:SetActive(false)
-- 		UIMgr.Close(UILvLimitBuyWnd.Name)
-- 	else
-- 		self.que:SetActive(true)
-- 	end
-- end

-- function M:Que()
-- 	self.que:SetActive(false)
-- end

-- function M:Quit()
-- 	self.que:SetActive(false)
-- 	UIMgr.Close(UILvLimitBuyWnd.Name)
-- end

-- function M:OnTog()
-- 	if self.sel.value == false then
-- 		LvLimitBuyMgr:SetStatus(0)
-- 	else
-- 		LvLimitBuyMgr:SetStatus(1)
-- 	end
-- end

function M:OnAdd(action,dic)
	if action == 10317 then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(self.dic)
	end
end

--//打开窗口
function M:OpenCustom()
	self:ShowData()
end

--//显示数据
function M:ShowData()
	local dataList = LvLimitBuyMgr:GetDataList()
	local num = #dataList
	if dataList == nil or num <= 0 then return end
	self:ReNewItemNum(num)

    for i=1,num do
		self.items[i]:InitItem(dataList[i])
	end
end

--//克隆限购物品条目
function M:CloneItem()
	local cloneObj = GameObject.Instantiate(self.item)
	local parent=self.grid.transform
	local AC=TransTool.AddChild
	local trans = cloneObj.transform
	local strans = self.item.transform
	AC(parent,trans)
	trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
	trans.localScale = strans.localScale
	cloneObj:SetActive(true)

	local cell = ObjPool.Get(UILvLimitBuyItem)
	cell:Init(cloneObj)

	local newName = ""
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.item.name, "99", tostring(#self.items + 1))
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.item.name, "99", "0"..tostring(#self.items + 1))
	else
		newName = string.gsub(self.item.name, "99", "00"..tostring(#self.items + 1))
	end
	cloneObj.name = newName

	self.items[#self.items + 1] = cell
	return cell
end

--重置条目数量
function M:ReNewItemNum(num)
	local len = #self.items
    for i=1,len do
        self.items[i]:Show(false)
    end
    if num <= len then
        for i=1,num do
            self.items[i]:Show(true)
		end
    else
        for i=1,len do
            self.items[i]:Show(true)
        end

		local needNum = num - len
        for i=1,needNum do
            self:CloneItem()
        end
    end
    self.itemGrid:Reposition()
end

function M:Clear(isRccnd)
	if isRccnd == true then return end
	self:SetLsnr("Remove")
	TableTool.ClearDicToPool(self.items)
	self.items = nil
end

return M