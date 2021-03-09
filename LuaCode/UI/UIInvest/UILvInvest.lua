--[[
 	authors 	:Liu
 	date    	:2019-4-9 20:00:00
 	descrition 	:化神投资界面
--]]

UILvInvest = Super:New{Name = "UILvInvest"}

local My = UILvInvest

require("UI/UIInvest/UILvInvestIt")

function My:Init(root)
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
    self.btnSpr = G(UISprite, trans, "BtnInvest", des)

    self.btnHelp = F(trans, "BtnHelp")
    self.slider = G(UISlider, trans, "SliderBg")
    self.eff = FC(trans, "fx_gm", des)
       
    S(self.btnInvest,self.OnInvest, self)
    S(self.btnHelp, self.OnHelp, self)

    self.itList = {}
    self.togList = {}
    self.sprList = {}
    self.labList = {}
    self.lab1List = {}
    self.curIndex = 0

    self.curInvesr = LvInvestMgr.investGold
    self.cfgList = GlobalTemp["116"].Value2

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
    self:InitView()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = LvInvestMgr
    mgr.eInvestBuy[func](mgr.eInvestBuy, self.RespInvestBuy, self)
    mgr.eInvestAward[func](mgr.eInvestAward, self.RespInvestAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10374 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应投资购买
function My:RespInvestBuy()
    self:UpInvestLab()
    self:UpBtnState()
    local gold = LvInvestMgr.investGold
    self:UpdateItem(gold)
    self:UpTog()
    self.grid:Reposition()
end

--响应领取投资奖励
function My:RespInvestAward()
    local gold = LvInvestMgr.investGold
    self:UpdateItem(gold)
    self.grid:Reposition()
end

function My:InitView()
    self.curInvesr = (self.curInvesr==0) and self.cfgList[3] or self.curInvesr
    local index = LvInvestMgr:GetType(self.curInvesr) or 3
    self.togList[index].value = true
    self.curIndex = index
    self:InitItem()
    self:UpInvestLab()
    self:UpBtnState()
end

--点击投资
function My:OnInvest()
    local mgr = LvInvestMgr
    local curInvest = mgr.investGold
    if curInvest >= self.curInvesr then
        local index = mgr:GetType(self.curInvesr)
        self.togList[index].value = false
        self.togList[3].value = true
        self:UpMenuData(3)
        return
    end
    local gold = RoleAssets.Gold
    local dValue = self.curInvesr - curInvest
    if gold >= dValue then
        local str = (curInvest==0) and "确定花费%d元宝参与投资计划吗?" or "确定花费%d元宝升级目前的投资计划吗?"
        MsgBox.ShowYesNo(string.format(str, dValue),self.ReqInvest, self)
    else
        MsgBox.ShowYesNo("您的元宝不足，是否充值?",self.OpenRecharge, self, "充值")
    end
end

--请求投资
function My:ReqInvest()
    LvInvestMgr:ReqInvestBuy(self.curInvesr)
end

--打开充值
function My:OpenRecharge()
    VIPMgr.OpenVIP(1)
end

function My:OnTog(go)
    local num = tonumber(go.name)
    if self.curIndex == num then return end
    self:UpMenuData(num)
end

--更新界面数据
function My:UpMenuData(num)
    self.curInvesr = self.cfgList[num]
    self:UpdateItem(self.curInvesr)
    self:UpBtnState()
    self.curIndex = num
end

function My:UpTog()
    local mgr = LvInvestMgr
    local index = mgr:GetType(mgr.investGold) or 0
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

--更新投资按钮状态
function My:UpBtnState()
    local curInvest = LvInvestMgr.investGold
    local str = ""
    local sprName = "btn_figure_non_avtivity"
    local isEnabled = true
    local lab = self.btnInvestName
    lab.fontSize = 24
    if curInvest ~= 0 then
        if curInvest >= self.curInvesr then
            if curInvest >= self.cfgList[3] then
                str = "[5d5451]已投资"
                sprName = "btn_figure_down_avtivity"
                self.eff:SetActive(false)
                isEnabled = false
            else
                lab.fontSize = 18
                str = "[772a2a]追加投资提高收益[-]"
            end
        else
            str = string.format("[772a2a]追加%s元宝提高收益", self.curInvesr - curInvest)
            lab.fontSize = 18
        end
    else
        str = "[772a2a]立即投资"
    end
    lab.text = str
    self.btnSpr.spriteName = sprName
    CustomInfo:SetEnabled(self.btnInvest, isEnabled)
end

--更新投资文本
function My:UpInvestLab()
    local gold = LvInvestMgr.investGold
    self.lblCurInvest.text = gold
end

--初始化投资项
function My:InitItem()
    local Add = TransTool.AddChild
    for i,v in ipairs(LvInvestCfg) do
        local go = Instantiate(self.cell)
        local tran = go.transform
        go:SetActive(true)
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(UILvInvestIt)
        it:Init(go, v)
        table.insert(self.itList, it)
    end
    self:UpdateItem(self.curInvesr)
end

--更新投资项
function My:UpdateItem(gold)
    local type = LvInvestMgr:GetType(gold)
    for i,v in ipairs(self.itList) do
        v:UpData(type)
    end
    self.grid:Reposition()
end

-- --更新投资项状态
-- function My:UpItemState()
--     for i,v in ipairs(self.itList) do
--         v:SetBtnState()
--     end
-- end

--点击说明
function My:OnHelp()
    UIComTips:Show(InvestDesCfg["16"].des, Vector3(-10,122,0))
end

function My:Open()
	self.go:SetActive(true)
end

function My:Close()
	self.go:SetActive(false)
end

--清理缓存
function My:Clear()
    self.dic = nil
    self.curIndex = 0
    ListTool.ClearToPool(self.itList)
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
end

return My