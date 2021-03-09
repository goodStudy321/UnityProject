--[[
    求购关注格子横向
]]
require("UI/Auction/RItem3")
RItem3X = Super:New{Name = "RItem3X"}

local M = RItem3X

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.grid = trans:GetComponent(typeof(UIGrid))
    self.item = T(trans,"Item_99")
    self.item:SetActive(false)

    self.items = {}
end
--重置条目数量
function M:Create(num)
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

function M:InitData(data)
    for i,v in ipairs(data) do
        self.items[i]:InitItem(v)
        self.items[i].go.name = tostring(v.id)
    end
end

function M:CloneItem()
	local cloneObj = GameObject.Instantiate(self.item)
	local parent=self.go.transform
	local AC=TransTool.AddChild
	local trans = cloneObj.transform
	local strans = self.item.transform
	AC(parent,trans)
	trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
	trans.localScale = strans.localScale
	cloneObj:SetActive(true)

	local cell = ObjPool.Get(RItem3)
	cell:Init(cloneObj)

	self.items[#self.items + 1] = cell
	return cell
end

function M:Show(value,resNum)
    self.go:SetActive(value)
    local num = #self.items
    if resNum then
        if value == true then
            for i=1,resNum do
                self.items[i]:Show(value)
            end
            for i = resNum + 1,num do
                self.items[i]:Show(not value)
            end
        end
    else
        for i=1,num do
            self.items[i]:Show(value)
        end
    end
end


function M:Dispose()
    TableTool.ClearDicToPool(self.items)
    self.items = nil
end

return M