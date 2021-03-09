UIInvest = Super:New{Name = "UIInvest"}

require("UI/UIInvest/InvestCell")
local M = UIInvest

function M:Init(root)
    self.togList = {}
    self.sprList = {}
    self.labList = {}
    self.lab1List = {}
    self.cellList = {}

    self.curInvesr = InvestMgr:GetCurInvest()

    self:InitUserData(root)
    self:InitView()
    self:SetLnsr("Add")
end

function M:SetLnsr(key)
    InvestMgr.eUpdateInvest[key](InvestMgr.eUpdateInvest, self.UpdateInvest, self)
    InvestMgr.eUpInvest[key](InvestMgr.eUpInvest, self.UpInvest, self)
    InvestMgr.eGetReward[key](InvestMgr.eGetReward, self.GetReward, self)
end

function M:GetReward()
    UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
end

--显示奖励的回调方法
function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpdateData(InvestMgr:GetReward())
	end
end

function M:InitUserData(root)
    self.go = root

    local trans = root.transform

    local G = ComTool.Get
    local S = UITool.SetBtnSelf
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local SetS = UITool.SetLsnrSelf

    self.grid = G(UIGrid, trans, "Container/ScrollView/Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)

    self.lblCurInvest = G(UILabel, trans, "CurInvest/lab2")

    self.btnInvest = F(trans, "BtnInvest")
    self.btnInvestName = G(UILabel, self.btnInvest, "Name") 

    self.btnHelp = F(trans, "BtnHelp")
    self.slider = G(UISlider, trans, "SliderBg")
    self.eff = FC(trans, "fx_gm", des)
       
    S(self.btnInvest,self.OnInvest, self)
    S(self.btnHelp, self.OnHelp, self)

    -- local popupList = G(UIPopupList, trans, "PopupList")
    -- self.popupList = popupList  
    self.cfgList = GlobalTemp["31"].Value2

    for i,v in ipairs(self.cfgList) do
        local tog = G(UIToggle, trans, "TogGrid/"..i)
        local spr = G(UISprite, trans, "TogGrid/"..i)
        local tran = tog.transform
        local lab = G(UILabel, tran, "lab")
        local lab1 = G(UILabel, tran, "lab1")

        SetS(tran, self.OnTog, self, self.Name)
        table.insert(self.togList, tog)
        table.insert(self.sprList, spr)
        table.insert(self.labList, lab)
        table.insert(self.lab1List, lab1)
    end
    self:UpTog()
    -- for i=1,#list do
    --     popupList:AddItem(tostring(list[i]))
    -- end
    -- popupList.value = tostring(list[3])
    -- EventDelegate.Add(popupList.onChange, EventDelegate.Callback(self.OnSelect, self))
end

function M:InitView()
    self.curInvesr = (self.curInvesr==0) and self.cfgList[3] or self.curInvesr
    local index = self:GetIndex() or 3
    self.togList[index].value = true
    self:InitCell()
    self:UpdateCurInvest()
    self:UpdateBtnInvest()
end

function M:UpdateCurInvest()
    self.lblCurInvest.text = InvestMgr:GetCurInvest()
end

function M:UpdateBtnInvest()
    local lv = GlobalTemp["31"].Value3
    if User.MapData.Level > lv then
        UITool.SetGray(self.btnInvest)
        self.btnInvestName.text = string.format("[5d5451]等级大于%d级[-]", lv) 
        return 
    end

    local curInvest = InvestMgr:GetCurInvest()
    local maxInvest = InvestMgr:GetInvest(3)
    local lab = self.btnInvestName
    lab.fontSize = 24
    if curInvest ~= 0 then
        if curInvest >= self.curInvesr then
            if curInvest >= maxInvest then
                UITool.SetGray(self.btnInvest)
                lab.text = "[5d5451]已投资[-]"
                self.eff:SetActive(false)
            else
                lab.fontSize = 18
                lab.text = "[772a2a]追加投资提高收益[-]"
            end
        else
            -- UITool.SetNormal(self.btnInvest)
            local str = string.format("[772a2a]追加%s元宝提高收益", self.curInvesr - curInvest)
            lab.fontSize = 18
            lab.text = str
        end
    else
        -- UITool.SetNormal(self.btnInvest)
        lab.text = "[772a2a]立即投资[-]"
    end
end

function M:InitCell()
    local cell = self.cell
    local parent = self.grid.transform
    local cellList = self.cellList
    local data = InvestMgr:GetInvestData(self.curInvesr)
    local len = #data
    for i=1,len do
        local go = Instantiate(cell)
        go:SetActive(true)
        TransTool.AddChild(parent, go.transform)
        local investCell = ObjPool.Get(InvestCell)
        investCell:Init(go)
        local isLast = data[i].level==self:GetLastCfg()
        investCell:UpdateCell(data[i], isLast)
        table.insert(cellList, investCell)
    end
    self.grid:Reposition()
end

--获取最后一档配置
function M:GetLastCfg()
    return InvestCfg[#InvestCfg].level
end

function M:UpdateCell(invest)
    local data = InvestMgr:GetInvestData(invest)
    if not data then return end
    local len = #data
    local list = self.cellList
    for i=1,len do
        local isLast = data[i].level==self:GetLastCfg()
        list[i]:UpdateCell(data[i], isLast)
    end
end

function M:UpdateInvest()
    self:UpdateCurInvest()
    self:UpdateBtnInvest()
    self:UpdateCell(self.curInvesr)
end

function M:UpInvest()
    self:UpTog()
end

function M:OnInvest()
    local curInvest = InvestMgr:GetCurInvest()
    if curInvest >= self.curInvesr then
        local index = self:GetIndex()
        self.togList[index].value = false
        self.togList[3].value = true
        self:UpMenuData(3)
        return
    end
    local gold = RoleAssets.Gold
    local dValue = self.curInvesr - curInvest
    if gold >= dValue then
        local str = ""
        if curInvest == 0 then
            str = "确定花费%d元宝参与投资计划吗?"          
        else
            str = "确定花费%d元宝升级目前的投资计划吗?"
        end  
        MsgBox.ShowYesNo(string.format(str, dValue),self.ReqInvest, self)
    else
        MsgBox.ShowYesNo("您的元宝不足，是否充值?",self.OpenRecharge, self, "充值")
    end
end

function M:ReqInvest()
    InvestMgr:ReqInvestGoldBuy(self.curInvesr)
end

function M:OpenRecharge()
    VIPMgr.OpenVIP(1)
end

function M:OnHelp()
    UIComTips:Show(InvestDesCfg["1"].des, Vector3(-10,122,0))
end

function M:OnTog(go)
    local num = tonumber(go.name)
    self:UpMenuData(num)
end

--更新界面数据
function M:UpMenuData(num)
    self.curInvesr = self.cfgList[num]
    self:UpdateCell(self.curInvesr)
    self:UpdateBtnInvest()
end

function M:UpTog()
    local index = self:GetIndex() or 0
    for i,v in ipairs(self.cfgList) do
        local state = index < i
        local list1 = self.labList
        local list2 = self.lab1List
        local list3 = self.sprList
        list1[i].gameObject:SetActive(state)
        list2[i].gameObject:SetActive(not state)
        if state then
            list1[i].text = v
            list3[i].spriteName = "untz"
        else
            list3[i].spriteName = "tz_on"
        end
    end
    local val = 0
    if index == 1 then
        val = 0.23
    elseif index == 2 then
        val = 0.91
    elseif index == 3 then
        val = 1
    end
    self.slider.value = val
end

function M:GetIndex()
    local index = nil
    for i,v in ipairs(self.cfgList) do
        if v == self.curInvesr then
            index = i
        end
    end
    return index
end

-- function M:OnSelect()
--     self.curInvesr = tonumber(self.popupList.value)
--     self:UpdateCell(self.curInvesr)
--     self:UpdateBtnInvest()
-- end

function M:Open()
	self.go:SetActive(true)
end

function M:Close()
	self.go:SetActive(false)
end

function M:Dispose()
    self:SetLnsr("Remove")
    TableTool.ClearUserData(self)
    TableTool.ClearDicToPool(self.cellList)
end

return M