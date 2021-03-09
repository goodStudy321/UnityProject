--[[
    开服累充的实例
--]]

UIAwardItem = Super:New{Name="UIAwardItem"}
local AD = UIAwardItem

function AD:Init(root, cfg, i)
    local CG = ComTool.Get
    local des = self.Name
    self.index = i
    self.root = root
    self.cfg = cfg
    self.go = root.gameObject
    self.itList = {}
    self.IngLab = CG(UILabel, root, "IngotText")
    self.Btn = CG(UIButton, root, "ImPayBtn",false)
    self.ImSpr = CG(UISprite, root, "ImPayBtn")
    self.Label = CG(UILabel, root, "ImPayBtn/Label")
    self.itemgrid = CG(UIGrid, root, "ItemGrid", des, false)
    self.BtnBox = CG(BoxCollider, root, "ImPayBtn")
    -- self.cell = TransTool.FindChild(root, "ItemCell", des)

    self:InitSelf(cfg, root, des)
end

--充值状态
function AD:PayState()
    self:ChangeBtnIcon(true)
    self.Label.text = "立即充值"
    UITool.SetBtnClick(self.root, "ImPayBtn", self.Name, self.OnClickPayBtn, self)
end

--可领取状态
function AD:CanAd()
    self:ChangeBtnIcon(true)
    self.Label.text = "领取"
    UITool.SetBtnClick(self.root, "ImPayBtn", self.Name, self.OnClickAwardBtn, self)
end

--已领取状态
function AD:HadAd()
    self:ChangeBtnIcon(false)
    self.Label.text = "已领"
    self.Btn.enabled = false
    local num = tonumber(self.root.gameObject.name)
    self.root.gameObject.name = num + 100
    -- self.BtnBox.enabled = false
end

--领取奖励按钮
function AD:OnClickAwardBtn()   
    local cfg = self.cfg
    AccuPayMgr:ReqGetAwardWord(cfg.id)
    --self:HadAd()
end

--点击立即充值按钮
function AD:OnClickPayBtn()
    --UITip.Log("功能暂未开发")
    VIPMgr.OpenVIP(1)
end

--初始化自身
function AD:InitSelf(cfg, root, des)
    self:InitAwardItem(cfg, root, des)
    self:InitWordAward(cfg)
    self:InitBtnState(cfg)
end

--初始化累充奖励
function AD:InitAwardItem(cfg, root, des)
    local list = self.itList
    local data = cfg.award
    for i=1,#data do
        local it = ObjPool.Get(UIItemCell)
        it:InitLoadPool( self.itemgrid.transform,1)
        it:UpData(data[i].I, data[i].B, data[i].N==2)
        table.insert(list, it)
    end
    self.itemgrid:Reposition()
end

--初始化累充数目
function AD:InitWordAward(cfg)
    local payNum = AccuPayInfo.selfPay
    if payNum==nil then payNum=0 end
    local all = cfg.id
    self.IngLab.text = payNum.."/"..all
end

--初始化累充奖励模块的状态
function AD:InitBtnState(cfg)
    local val = AccuPayInfo.RewardDic[cfg.id]
    if val==nil then val=1 end
    if val==1 then
        self:PayState()
    elseif val==2 then
        self:CanAd()
    elseif val==3 then
        self:HadAd()
    end
end

--更改按钮颜色
function AD:ChangeBtnIcon(isActive)
    local spr = self.ImSpr
    -- self.Btn.normalColor = Color.New(1,1,1,1)
    spr.color = Color.New(1,1,1,1)
    if isActive == true then
        -- spr.spriteName = "btn_figure_non_avtivity"
        self.Btn.normalSprite = "btn_figure_non_avtivity"
    elseif isActive == false then
        -- spr.spriteName = "btn_figure_down_avtivity"
        self.Btn.normalSprite = "btn_figure_down_avtivity"
    end
end


function AD:Dispose()
    TableTool.ClearListToPool(self.itList)
    TableTool.ClearUserData(self)
end

return AD