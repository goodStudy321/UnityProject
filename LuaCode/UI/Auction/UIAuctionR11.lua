require("UI/Auction/RItem11")
UIAuctionR11 = Super:New{Name = "UIAuctionR11"}

local M = UIAuctionR11

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local tip = "拍卖行右侧面板1"

M.items = {}

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.sv = C(UIScrollView,trans,"SV",tip,false)
    self.grid = C(UIGrid,trans,"SV/grid",tip,false)
    self.item = T(trans,"SV/grid/Item_99")
    self.item:SetActive(false)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    AuctionMgr.eUpSecType[key](AuctionMgr.eUpSecType,self.ShowData,self)
end

function M:ShowData()
    local dataList = AuctionMgr:GetSecIdList()
    local num = #dataList
    if dataList == nil or num <= 0 then return end
    self:ReNewItemNum(num)
    for i=1,num do
        self.items[i]:InitItem(dataList[i], function(id) self:ClickSelItem(id) end)
    end
end

function M:ClickSelItem(secId)
    AuctionMgr:SetSecId(secId)
    AuctionMgr:ReqSecType()
    self:Close()
    UIAuctionR12:Open()
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

	local cell = ObjPool.Get(RItem11)
	cell:Init(cloneObj)

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
    self.grid:Reposition()
end

function M:Open()
    self.go:SetActive(true)
    self:ShowData()
end

function M:Close()
    self.go:SetActive(false)
end

function M:Dispose()
    self:SetLsner("Remove")
    TableTool.ClearDicToPool(self.items)
end

return M