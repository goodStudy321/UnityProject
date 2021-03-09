UIMonthInvest = Super:New{Name = "UIMonthInvest"}

require("UI/UIMonthInvest/MonthCardCell")

local M = UIMonthInvest

function M:Init(root)
    self.cellList = {}
    self:InitUserData(root)
    self:InitView()
    self:SetLnsr("Add")
end

function M:SetLnsr(key)
    MonthInvestMgr.eUpdateMonth[key](MonthInvestMgr.eUpdateMonth, self.UpdateMonth, self)
    MonthInvestMgr.eGetReward[key](MonthInvestMgr.eGetReward, self.GetReward, self)
end

function M:GetReward()
    UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
end

--显示奖励的回调方法
function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(MonthInvestMgr:GetReward())
	end
end

function M:InitUserData(root)
    self.go = root

    local trans = root.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local F = TransTool.Find
    local FC = TransTool.FindChild

    self.labRemainTime = G(UILabel, trans, "RemainTime")

    self.btnInvest = F(trans, "BtnInvest")
    self.btnSpr = G(UISprite, trans, "BtnInvest")
    self.btnInvestName = G(UILabel, self.btnInvest, "Name")
    S(self.btnInvest, self.OnInvest, self)

    local btnHelp = F(trans, "BtnHelp")
    S(btnHelp, self.OnHelp, self)

    self.grid = G(UIGrid, trans, "Container/ScrollView/Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)
end

function M:InitView()
    self:UpdateRemainDay()
    self:UpdateBtn()
    self:InitCell()
end

function M:InitCell()
    local cell = self.cell
    local parent = self.grid.transform
    local cellList = self.cellList
    local data = MonthInvestMgr:GetMonthCardData()
    local len = #data

    for i=1,len do
        local go = Instantiate(cell)
        go:SetActive(true)
        TransTool.AddChild(parent, go.transform)
        local monthCardCell = ObjPool.Get(MonthCardCell)
        monthCardCell:Init(go)
        monthCardCell:UpdateCell(data[i])
        table.insert(cellList, monthCardCell)
    end
    self.grid:Reposition()
end

function M:UpdateMonth()
    local list = self.cellList
    local len = #list
    local data =  MonthInvestMgr:GetMonthCardData()
    for i=1,len do
        list[i]:UpdateCell(data[i])
    end
    self:UpdateBtn()
    self:UpdateRemainDay()
end

function M:UpdateBtn()
    local state = MonthInvestMgr:CanBuy()
    if state then
        -- UITool.SetNormal(self.btnInvest)      
        CustomInfo:SetBtnState(self.btnInvest, true)
        self.btnSpr.spriteName = "btn_figure_non_avtivity"
        self.btnInvestName.text = string.format("[772a2a]投资%d元宝[-]", GlobalTemp["32"].Value3)
    else
        -- UITool.SetGray(self.btnInvest)
        CustomInfo:SetBtnState(self.btnInvest, false)
        self.btnSpr.spriteName = "btn_figure_down_avtivity"
        self.btnInvestName.text = "[5d5451]已投资[-]"
    end
end

function M:UpdateRemainDay()
    local num = MonthInvestMgr:GetRemainDay()
    if num == 0 then
        self.labRemainTime.gameObject:SetActive(false)
    else
        self.labRemainTime.gameObject:SetActive(true)
        self.labRemainTime.text = string.format("[FF8B8BFF]剩余可领天数：[00FF00FF]%d[-]天[-]", num)
    end
end

function M:OnInvest()
    local gold = RoleAssets.Gold
    local need = GlobalTemp["32"].Value3
    if gold >= need then     
        MsgBox.ShowYesNo(string.format("确定花费%d元宝参与月卡投资吗?", need),self.ReqInvest, self)
    else
        MsgBox.ShowYesNo("您的元宝不足，是否充值?",self.YseCb, self, "充值")
    end
end

function M:ReqInvest()
    MonthInvestMgr:ReqMonthCardBuy()
end

function M:YseCb()
    VIPMgr.OpenVIP(1)
end

function M:OnHelp()
    UIComTips:Show(InvestDesCfg["3"].des, Vector3(35, 245, 0))
end

function M:Open()
	self.go:SetActive(true)
end

function M:Close()
	self.go:SetActive(false)
end

function M:Dispose()
    self:SetLnsr("Remove")
    TableTool.ClearUserData(self)
end


return M