RItem22 = Super:New{Name = "RItem22"}

local M = RItem22

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.cellRoot = T(trans,"cell").transform
    self.status1 = T(trans,"statusLb1")
    self.status2 = T(trans,"statusLb2")
    self.name = C(UILabel,trans,"name",tip,false)
    self.price = C(UILabel,trans,"statusLb1/price/Num",tip,false)

    self.lb1 = C(UILabel,trans,"statusLb2",tip,false)
    self.lb2 = C(UILabel,trans,"statusLb2/lb",tip,false)

    self.time = C(UILabel,trans,"time",tip,false)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:InitItem(data)
    if data == nil then return end
    self.data = data
    if not self.item then
        self.item = ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellRoot)
    end
    local item = self.item
    local id = self.data.type_id
    local num = self.data.num
    item:UpData(id,num)
    
    self.name.text = self.data.name
    local time = DateTool.GetDate(self.data.time):ToString("MM月dd日 HH:mm")
    self.time.text = time

    local firId = AuctionMgr:GetFirId()

    local price = self.data.gold
    if price == 0 then
        self.status2:SetActive(true)
        self.status1:SetActive(false)
        self.lb1.text = "流拍"
        self.lb2.text = "道具已邮件返还"
        if firId == "3" then
            self.lb1.text = "竞拍失败"
            self.lb2.text = "元宝已通过邮件发送"
        elseif firId == "4" then
            self.lb2.text = "该道具已被系统回收"
        end
    elseif price == -1 then
        self.status2:SetActive(true)
        self.status1:SetActive(false)
        self.lb1.text = "下架"
        self.lb2.text = "道具已邮件返还"
    else
        self.status1:SetActive(true)
        self.status2:SetActive(false)
        self.price.text = price
    end
end

function M:Dispose()
    self.data = nil
    if self.item ~= nil then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    TableTool.ClearUserData(self)
end

function M:Show(value)
    self.go:SetActive(value)
end

return M