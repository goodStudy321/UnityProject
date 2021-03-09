MonthCardCell = Super:New{Name = "MonthCardCell"}

local M = MonthCardCell

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.labDes = G(UILabel, trans, "Des")
    self.labCount = G(UILabel, trans, "Count")

    self.btnGet = FC(trans, "BtnGet")
    self.btnSpr = G(UISprite, trans, "BtnGet")
    self.labBtnName = G(UILabel, self.btnGet.transform, "Label")
    UITool.SetLsnrSelf(self.btnGet, self.OnGet, self)

    self.tips = FC(trans, "Tips")
    self.hadGet = FC(trans, "HadGet")
end

function M:UpdateCell(data)
    self.data = data  
    local hadGet = data.hadGet == 2
    if data.day ~= 0 then
        self.labDes.text = string.format("第%d天可领", data.day)
    else
        self.labDes.text = "投资立返"
    end
    self.labCount.text = hadGet and 0 or data.count
    self:UpdateBtn(data.hadGet)
end

function M:UpdateBtn(state)
    if state == 0 then
        -- UITool.SetGray(self.btnGet)
        CustomInfo:SetBtnState(self.btnGet, false)
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.labBtnName.text = "[5d5451]领取[-]"
        self:SetBtnActive(true)
    elseif state == 1 then
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
    MonthInvestMgr:MonthCardReward(self.data.day)
end

function M:Dispose()
    TableTool.ClearDic(self.data)
    TableTool.ClearUserData(self)
end

return M