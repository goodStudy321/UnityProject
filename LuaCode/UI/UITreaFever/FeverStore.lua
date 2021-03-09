require("UI/UITreaFever/FeverStoreItem")
FeverStore = Super:New{Name = "FeverStore"}
local M = FeverStore

local US = UITool.SetBtnClick
local T = TransTool.FindChild
local C = ComTool.Get
local CS = ComTool.GetSelf
local Add = TransTool.AddChild

function M:Init(go)
    self.go = go
    local trans = go.transform
    local des = self.Name

    self.sv = C(UIScrollView,trans,"sv",des)
    self.grid = C(UIGrid,trans,"sv/grid",des)
    self.item = T(trans,"sv/grid/item")
    self.item:SetActive(false)
    self.items = {}
    self:ShowData()
end

function M:ShowData()
    local data = TreaFeverMgr:GetStoreAward()
    local num = #data
    if data == nil or num <= 0 then
        self:ReNewItemNum(0)
        return
    end
    self:ReNewItemNum(num)
    for i=1,num do
        self.items[i]:InitItem(data[i])
    end
    self.sv:ResetPosition()
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

	local cell = ObjPool.Get(FeverStoreItem)
	cell:Init(cloneObj)

	self.items[#self.items + 1] = cell
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

function M:UpShow(value)
    self.go:SetActive(value)
end

function M:Dispose()
    TableTool.ClearDicToPool(self.items)
	self.items = nil
end

return M