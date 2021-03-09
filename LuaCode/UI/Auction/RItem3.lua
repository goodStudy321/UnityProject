RItem3 = Super:New{Name = "RItem3"}

local M = RItem3

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.cellRoot = T(trans,"cell").transform
    self.name = C(UILabel,trans,"name",tip,false)

    self.btnLb = C(UILabel,trans,"oneBtn/Label",tip,false)

    self.state = 0

    US(trans, "oneBtn", tip, self.OnAttr, self)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    AuctionMgr.eUpAttr[key](AuctionMgr.eUpAttr,self.UpBtnStatus,self)
end

function M:UpBtnStatus(id,type)
    if id == self.id then
        if type == 1 then
            self.btnLb.text = "关注"
            self.state = 0
        else
            self.btnLb.text = "取消关注"
            self.state = 1
        end
    end
end

function M:InitItem(data)
    self.id = data.id
    local id = self.id
    local careList = AuctionMgr:GetCareList()
    self.btnLb.text = "关注"
    self.state = 0
    if careList ~= nil then
        for i,v in ipairs(careList) do
            if v == id then
                self.btnLb.text = "取消关注"
                self.state = 1
                break
            end
        end
    end
    if id == nil then return end
    if not self.item then
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellRoot)
    end
    local item = self.item
    item:UpData(id)

    local data = ItemData[tostring(id)]
    local qua = UIMisc.LabColor(data.quality)
    local name = qua..data.name
    
    self.name.text = name
end

function M:Show(value)
	self.go:SetActive(value)
end

-- 关注
function M:OnAttr()
    AuctionMgr:RepCareGoods(self.state,self.id)
end


function M:Dispose()
    self:SetLsner("Remove")
    self.state = 0
    if self.item ~= nil then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    TableTool.ClearUserData(self)
end

return M