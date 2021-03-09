UIActItem = Super:New{Name = "UIActItem"}

local M = UIActItem

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local trans = go.transform

    self.go = go
    self.grid = G(UIGrid, trans, "Grid")
    self.des = G(UILabel, trans, "Des")
    self.remainCount = G(UILabel, trans, "RemianCount")
    self.btnGet = FC(trans, "BtnGet")
    self.btnPay = FC(trans, "BtnPay")
    self.hadGet = FC(trans, "HadGet")
    self.notGet = FC(trans, "NotGet")

    S(self.btnGet, self.OnGet, self)
    S(self.btnPay, self.OnPay, self)
end

function M:OnGet()
    if self.data then
        FestivalActMgr:ReqBgActReward(self.data.type, self.data.id)
    end
end

function M:OnPay()
    VIPMgr.OpenVIP(1)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateReward()
    self:UpdateCondition()
    self:UpdateRemainCount()
end

function M:UpdateCondition()
    self:UpdateBtnState()
    self:UpdateDes()
end

function M:UpdateBtnState()
     local state = self.data.state
     if state == 1 then
        self:SetState(false, true, false)
     elseif state == 2 then
        self:SetState(true, false, false)
     elseif state == 3 then
        self:SetState(false, false, true)
     end
end

function M:SetState(s1, s2, s3)
    self.btnGet:SetActive(s1)
    self.hadGet:SetActive(s3)

    local type = self.data.type
    if type == FestivalActMgr.LJCZ or type == FestivalActMgr.DCDL then
        self.btnPay:SetActive(s2)
        self.notGet:SetActive(false)
    elseif type == FestivalActMgr.LJXF then
        self.notGet:SetActive(s2)
        self.btnPay:SetActive(false)
    end   
end

function M:UpdateRemainCount()
    local type = self.data.type
    if type == FestivalActMgr.DCDL then
        local count = self.data.schedule
        self.remainCount.text = string.format("当前可领取次数：%s", count);
        self.remainCount.gameObject:SetActive(true);
        return;
    end

    local count =  self.data.remainCount
    if count ~= -1 then
        self.remainCount.text = string.format("剩余数量：%s", self.data.remainCount)
        self.remainCount.gameObject:SetActive(true)
    else
        self.remainCount.gameObject:SetActive(false)
    end
end

function M:UpdateDes()
    local data = self.data
    local type = data.type
    if type == FestivalActMgr.DCDL then --单充大礼
        self.des.text = data.des;
        return;
    end
    local num = ""
    if data.schedule < data.target then
        num = data.schedule
    else
        num = data.target
    end
    self.des.text = string.format("[F4DDBDFF]%s[E5B45FFF](%s/%s)[-]",  data.des, num, data.target)
end

function M:UpdateReward()
    local data = self.data.rewardList
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].id, data[i].num, data[i].effNum==1)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateReward(data[i])
        end
    end
    self.grid:Reposition()
end


function M:CreateReward(data)
    local cell = ObjPool.Get(UIItemCell)
    cell:InitLoadPool(self.grid.transform, 0.7)
    cell:UpData(data.id, data.num, data.effNum==1)
    table.insert(self.cellList, cell)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Dispose()
    self.data = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M