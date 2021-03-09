RItem21 = Super:New{Name = "RItem21"}

local M = RItem21

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local S = UITool.SetLsnrSelf;

function M:Ctor()
    self.IsSelect = false;
end

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.isStart = false
    self.ExpectGold = 0

    self.cellRoot = T(trans,"cell").transform
    self.name = C(UILabel,trans,"name",tip,false)
    self.curPriceLb = C(UILabel,trans,"price",tip,false)
    self.sellPriceLb = C(UILabel,trans,"sellPrice",tip,false)
    self.timeLb = C(UILabel,trans,"timeLb",tip,false)
    self.statusLb = C(UILabel,trans,"statusLb",tip,false)
    self.timeLb = C(UILabel,trans,"timeLb",tip,false)
    self.desLb = C(UILabel,trans,"desLb",tip,false)

    self.mHighlight = T(trans, "Highlight");
    S(go, self.OnSelect, self, self.Name, false);
end

function M:OnSelect()
    self.IsSelect = not self.IsSelect;
    
    local oldSelect = UIAuctionR21.mSelectItem;
    if oldSelect ~= nil then
        oldSelect.IsSelect = false;
        oldSelect:SetHightLight();
    end
    UIAuctionR21:UpdateSeletDic();
    self:SetHightLight();
end

function M:SetHightLight()
    self.mHighlight:SetActive(self.IsSelect)
end

function M:IsActive()
    return self.go.activeSelf;
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
    

    local status = self.data.aucId
    self.statusLb.gameObject:SetActive(status ~= "0")
    if status == "0" then
        self.curPriceLb.text = 0
    else
        self.curPriceLb.text = self.data.cur_gold
    end
    self:SetHightLight();
    self:ShowTime()
end

function M:ShowTime()
    local now = TimeTool.GetServerTimeNow()*0.001
    local endWaitTime = self.data.auction_time
    local endTime = self.data.end_time
    local lerp = endWaitTime - now
    local index = VIPMgr.GetVIPLv() + 1
    local Ratio = VIPLv[index].arg22*0.0001
    local ratio = 1 - Ratio
    if lerp <= 0 then
        lerp = endTime - now
        self.isStart = true
        local status = self.data.aucId
        self.ExpectGold = 0
        if status ~= "0" then
            self.ExpectGold = math.floor(self.data.cur_gold *ratio)
            self.desLb.text = "竞价中"
        else
            self.desLb.text = "暂时无人出价"
        end
        self.sellPriceLb.text = self.ExpectGold
    else
        self.isStart = false
        self.desLb.text = "展示中"
    end
    self:StartTime(lerp)
end

function M:StartTime(dValue)
    if not dValue then return end
    if not self.timer then
        self.timer=ObjPool.Get(DateTimer)
    end
    local timer=self.timer
    timer:Stop()
    if dValue<=0 then
        timer.remain = ""
        self:EndTime()
    else
        timer.seconds=dValue
        timer.fmtOp = 3
        timer.invlCb:Add(self.UpTime,self)
        timer.complete:Add(self.EndTime, self)
        timer:Start()
        self:UpTime()
    end
end

function M:UpTime()
    local lab = ""
    if self.isStart == true then
        lab = "[00FF00]"..self.timer.remain.."后结束"
    else
        lab = "[FF0000]"..self.timer.remain.."后开始"
    end
    self.timeLb.text = lab
end

function M:EndTime()
    if self.isStart then
        self.timer:Stop()
    else
        self:ShowTime()
    end
end

function M:Show(value)
	self.go:SetActive(value)
end

function M:Dispose()
    self.ExpectGold = 0

    self.IsSelect = false;

    if self.item ~= nil then
        self.item:DestroyGo()
        ObjPool.Add(self.item)
        self.item = nil
    end
    self.isStart = false
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
	end
    TableTool.ClearUserData(self)
end

return M