--[[
    每日首冲
]]

UIFirstPay = UIBase:New{Name = "UIFirstPay"}
local My = UIFirstPay
local dayLabTab = {"可领","已领"}

require("UI/UIOpenService/UIFirstModel")

function My:InitCustom()
    local trans = self.root
    local TF = TransTool.FindChild
    local T = TransTool.Find
    local CG = ComTool.Get
    local des = self.Name
    local UC = UITool.SetLsnrSelf
    self.itList = {}


    self.btnEff = TF(trans,"tween/GetBtn/fx_gm")
    self.btnTween = CG(TweenScale,trans,"tween",des,false)
    self.btnTweenSp = T(trans,"tween",des)
    -- self.btnTween.from = Vector3.New(1,1,1)
    -- self.btnTween.to = Vector3.New(1.2,1.2,1.2)
    -- self.btnTween.duration = 1

    self.Tog1 = CG(UIToggle,trans,"tog/tog1",des)
    self.Tog2 = CG(UIToggle,trans,"tog/tog2",des)
    self.Tog3 = CG(UIToggle,trans,"tog/tog3",des)

    UC(self.Tog1,self.Tog1Fun,self,des,false)
    UC(self.Tog2,self.Tog2Fun,self,des,false)
    UC(self.Tog3,self.Tog3Fun,self,des,false)

    local TogLab1 = CG(UILabel,trans,"tog/tog1/lab")
    local TogLab2 = CG(UILabel,trans,"tog/tog2/lab")
    local TogLab3 = CG(UILabel,trans,"tog/tog3/lab")
    TogLab1.text = "第1天可领"
    TogLab2.text = "第2天可领"
    TogLab3.text = "第3天可领"

    self.togLabTab = {TogLab1,TogLab2,TogLab3}

    self.spLab = CG(UISprite,trans,"bg/l3",des)
    self.leftLab = CG(UILabel,trans,"bg/Lab1")
    self.rightLab = CG(UILabel,trans,"bg/Lab2")

    self.Btn = T(trans, "tween/GetBtn", des)
    self.BtnLab = CG(UILabel, trans, "tween/GetBtn/Label", des)
    self.Grid = CG(UIGrid, trans, "Grid", des)
    self.cell = TF(trans, "ItemCell", des)
    self.bgTex = CG(UITexture, trans, "bg", des)

    self.UIModel = ObjPool.Get(UIFirstModel)
    self.UIModel:Init(TF(trans, "UIModel"))

    self.typeOne = TF(trans, "tween/GetBtn/1", des)
    self.typeTwo = TF(trans, "tween/GetBtn/2", des)
    self.typeThree = TF(trans, "tween/GetBtn/3", des)

    self.typeTwoSp = CG(UISprite,trans,"tween/GetBtn/2",des)

    UITool.SetBtnClick(trans, "CloseBtn", des, self.OnClose, self)
end

--打开首充界面
function My:OpenFirsyPay()
    local isShield = FirstPayMgr:IsCanShield()
    if isShield == true then
        return
    end
    UIMgr.Open(UIFirstPay.Name)
end

--设置可领取状态图标
--day:天数
function My:SetTypeSp(day)
    local str = ""
    local tab = {"title","title_2","title_3"}
    self.typeTwoSp.spriteName = tab[day]
    -- self.typeTwoSp:MakePixelPerfect()
end

function My:OpenTab()
    local openIndex = self.openIndex
    if openIndex == 1 then
        self:Tog1Fun()
    elseif openIndex == 2 then
        self:Tog2Fun()
    elseif openIndex == 3 then
        self:Tog3Fun()
    end
end

--第一天
function My:Tog1Fun()
    if self:IsCurTab(1) == true then
        return
    end
    self.Tog1.value = true
    self.index = 1
    local cfg = FirstPayCfg[1]
    self:InitItem(cfg)
end

--第二天
function My:Tog2Fun()
    if self:IsCurTab(2) == true then
        return
    end
    self.Tog2.value = true
    self.index = 2
    local cfg = FirstPayCfg[2]
    self:InitItem(cfg)
end

--第三天
function My:Tog3Fun()
    if self:IsCurTab(3) == true then
        return
    end
    self.Tog3.value = true
    self.index = 3
    local cfg = FirstPayCfg[3]
    self:InitItem(cfg)
end

function My:IsCurTab(indexT)
    local indexTab = self.index
    if indexTab and indexT == indexTab then
        return true
    end
    return false
end

function My:GetOpenIndex()
    local index = 1
    local isGet = FirstPayMgr:IsPayState()
    local tab = FirstPayInfo.rewardTab
    local openDay = FirstPayInfo.openServerDay
    if isGet == false then
        self.openIndex = 1
        return
    end
    for i = 1,3 do
        if tab[i] == nil then
            index = i
            break
        end
    end
    self.openIndex = index
end

function My:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

--icon
function My:UpIcon()
	self:UnloadTex()
	self.iconName = "bg_gift1.png"
	AssetMgr:Load(self.iconName,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	self.bgTex.mainTexture=obj
end

function My:UnloadTex()
	if self.iconName then 
		AssetMgr:Unload(self.iconName,".png",false)
	end
	self.iconName=nil
end

function My:SetLnsr(func)
    -- FirstPayMgr.eFirstInfo[func](FirstPayMgr.eFirstInfo, self.RespFirstInfo, self)
    FirstPayMgr.eGetAward[func](FirstPayMgr.eGetAward, self.RespGetAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:OnAdd(action, dic)
    if action==10308 then
        self.dic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.RewardCb, self)
    end
end

function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:UpdateData(self.dic)
    end
end

function My:RespFirstInfo()
    self:InitBtnState()
end

function My:RespGetAward()
    self:RefreshBtnState()
end

function My:OpenCustom()
    self:GetOpenIndex()
    self:SetLnsr("Add")
    self:OpenTab()
    self:UpIcon()
    self:SetTogLab()
end

function My:InitItem(cfg)
    if cfg == nil then
        iTrace.eError("GS","奖励配置为空")
        return
    end
    local n = cfg
    local len = #n.award
    local list = self.itList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(n.award[i].k,n.award[i].v)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local cell = ObjPool.Get(UIItemCell)
            cell:InitLoadPool(self.Grid.transform,0.8)
            cell:UpData(n.award[i].k,n.award[i].v)
            cell:SetActive(true)
            list[#list+1] = cell
        end
    end
    -- for i,j in ipairs(n.award) do
    --     local cell = ObjPool.Get(UIItemCell)
    --     cell:InitLoadPool(self.Grid.transform,0.8)
    --     cell:UpData(j.k, j.v)
    --     list[#list+1] = cell
    -- end
    if self.UIModel then
        local cate = User.MapData.Category
        if cate==1 then
            self.UIModel:Update(n.Weapon1, n.Clothes1)
        else
            self.UIModel:Update(n.Weapon2, n.Clothes2)            
        end
    end
    self.Grid:Reposition()
    self.spLab.spriteName = n.iconPath
    self.leftLab.text = n.WeaponTxt
    self.rightLab.text = n.FashionTxt
    self:InitBtnState(self.index)
    self.spLab:MakePixelPerfect()
end

function My:SetTogLab()
    local openDay = FirstPayInfo.openServerDay
    local val = FirstPayMgr:IsPayState()
    local tab = FirstPayInfo.rewardTab
    local togLabTab = self.togLabTab
    if val == false then
        return
    end
    if openDay > 3 then
        openDay = 3
    end
    for i = 1,openDay do
        if tab[i] == nil then
            -- togLabTab[i].text = "可领"
        else
            -- togLabTab[i].text = "已领"
        end
    end
end

--day : 天数
function My:InitBtnState(day)
    local index = day
    if index == nil then
        index = self.index
    end
    local val = FirstPayMgr:IsPayState()
    local openDay = FirstPayInfo.openServerDay
    local tab = FirstPayInfo.rewardTab
    if val == false then
        self:PayState()
        return
    end
    if val == true then
        if tab[index] == nil then
            self:GetState()
        else
            self:HadState()
        end
    end
end

function My:RefreshBtnState()
    local curDay = FirstPayInfo.curRewardDay
    local nextDay = curDay + 1
    local openDay = FirstPayInfo.openServerDay
    if curDay == nil then
        iTrace.eError("GS","当前领取奖励天数 curDay===",curDay)
        return
    end
    -- self.togLabTab[curDay].text = "已领"
    if nextDay > 3 then
        self:HadState()
        return
    end
    self.openIndex = nextDay
    self:OpenTab()
end

function My:ClearIcon()
    if self.itList then
        for k,v in pairs(self.itList) do
            v:DestroyGo()
            ObjPool.Add(v)
            self.itList[k] = nil
        end
    end
end

function My:PayState()
    self:ShowDif(1)
    UITool.SetLsnrClick(self.root, "tween/GetBtn", self.Name, self.OnPayClick, self)   
end

function My:GetState()
    self:ShowDif(2)
    UITool.SetLsnrClick(self.root, "tween/GetBtn", self.Name, self.OnGetClick, self)
end

function My:HadState()
    self:ShowDif(3)
    -- UITool.SetGray(self.Btn)
end

--state:1,2,3
--1:充值   2：可领取    3：已领取
function My:ShowDif(state)
    local day = self.index
    if day and state == 2 then
        self:SetTypeSp(day)
    end
    self.typeOne:SetActive(state == 1)
    self.typeTwo:SetActive(state == 2)
    self.typeThree:SetActive(state == 3)
    self.btnEff:SetActive(state ~= 3)
    local vec = nil
    if state == 3 then
        vec = Vector3.New(1,1,1)
        -- UITool.SetGray(self.btnTweenSp)
    else
        vec = Vector3.New(1.2,1.2,1.2)
        -- UITool.SetNormal(self.btnTweenSp)
    end
    self.btnTween.to = vec
end

function My:OnPayClick()
    --UITip.Log("功能暂未开发")
    self:Close()
    VIPMgr.OpenVIP(1)
end

function My:OnGetClick()
    local openDay = FirstPayInfo.openServerDay
    local tab = FirstPayInfo.rewardTab
    local day = self.index
    if day > openDay then
        UITip.Error("该奖励尚未可以领取")
        return
    end
    if openDay >= day and tab[day] == nil then
        FirstPayMgr:ReqGetAward(day)
    end
end

function My:CloseCustom()

end

function  My:Clean()
    self.Btn = nil
    self.Grid = nil
    self.cell = nil
    self.index = nil
    for i = 1,#self.togLabTab do
        self.togLabTab[i] = nil
    end
end

function My:DisposeCustom()
    self:UnloadTex()
    self:ClearIcon()
    self:Clean()
    self.dic = nil
    self:SetLnsr("Remove")
    if self.UIModel then
        self.UIModel:Dispose()
        self.UIModel = ObjPool.Add(UIFirstModel)
    end
    -- TableTool.ClearListToPool(self.itList)
    -- ListTool.ClearToPool(self.itList)
end

return My