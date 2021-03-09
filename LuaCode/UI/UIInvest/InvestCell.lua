InvestCell = Super:New{Name = "InvestCell"}

local M = InvestCell

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    
    self.labDes = G(UILabel, trans, "Des")
    self.labCount = G(UILabel, trans, "Count")
    self.labNextCount = G(UILabel, trans, "nextCount")

    self.btnGet = FC(trans, "BtnGet")
    self.btnSpr = G(UISprite, trans, "BtnGet")
    self.labBtnName = G(UILabel, self.btnGet.transform, "Label")
    
    self.tips = FC(trans, "Tips")
    self.hadGet = FC(trans, "HadGet")

    UITool.SetLsnrSelf(self.btnGet, self.OnGet, self)
end

function M:UpdateCell(data, isLast)
    self.data = data
    local curInvest = InvestMgr:GetCurInvest()
    if curInvest == 0  then
        self.labCount.text = data.count
    else
        if data.hadGet == 2 then
            self.labCount.text = data.count
        else
            if data.invest < curInvest then
                self.labCount.text = data.count
            elseif data.invest == curInvest then
                self.labCount.text = InvestMgr:GetRewardDvalue(curInvest, data.level)
            else
                local temp = InvestMgr:GetInvestLevelData(curInvest, data.level)
                self.labCount.text = temp.count
                self.labNextCount.text = data.count
            end
        end
        local state = curInvest < data.invest
        self.labNextCount.gameObject:SetActive(state)
    end
    local des = ""
    if data.level == 0 then
        des = "[EE9A9EFF]存入当天立返[00FF00FF]100%[-]绑元"
    -- elseif isLast then
    --     des = "[EE9A9EFF]达到化神30级累计可获得[00FF00FF]10倍[-]返利"
    else
        des = string.format("[EE9A9EFF]达到%s级可领取[00FF00FF]%d%%[-]绑元", UIMisc.GetLv(data.level), math.floor(data.count*100/data.invest))
    end
    self.labDes.text = des

    self:SetBtnState(data.hadGet)
end

function M:SetBtnState(state)
    if state == 0 then  --不可领取
        -- UITool.SetGray(self.btnGet)
        CustomInfo:SetBtnState(self.btnGet, false)
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.labBtnName.text = "[5d5451]领取[-]"
        self:SetBtnActive(true)
    elseif state == 1 then  --可领取
        -- UITool.SetNormal(self.btnGet)
        CustomInfo:SetBtnState(self.btnGet, true)
        self.btnSpr.spriteName = "btn_figure_non_avtivity"
        self.labBtnName.text = "[772a2a]领取[-]"
        self:SetBtnActive(true)
    else
        self:SetBtnActive(false)
    end
end

function M:SetBtnActive(bool)
    self.btnGet:SetActive(bool)
    self.hadGet:SetActive(not bool)
end

function M:OnGet()
    InvestMgr:ReqInvestGoldReward(self.data.level)
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
end

return M