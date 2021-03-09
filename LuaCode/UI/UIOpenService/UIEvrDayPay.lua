--[[
    每日累充
]]--

UIEvrDayPay = UIBase:New{Name = "UIEvrDayPay"}
local My = UIEvrDayPay

require("UI/UIOpenService/UIEvrPayItem")
require("UI/UIOpenService/UIEvrCountItem")
local Info = require("Data/OpenService/EvrDayInfo")

-- local togList = {}

function My:InitCustom()
    local trans = self.root
    local TF = TransTool.FindChild
    local T = TransTool.Find
    local CG = ComTool.Get
    local des = self.Name

    self.togList = {}
    self.CountDic = {}
    self.actionList = {}

    self.payItem = TF(trans, "Pay")
    self.EvrPay = ObjPool.Get(UIEvrPayItem)
    self.countItem = TF(trans, "Count/CountItem")
    self.CGrid = T(trans, "Count/CGrid", des)   
    
    self.bgTex = CG(UITexture, trans, "bg", des)

    local BtnGrid = TF(trans, "Togs").transform
    for i=1,3 do
        local tg = CG(UIToggle, BtnGrid, "Tog"..i, des, false)
        local action = TF(BtnGrid, "Tog"..i.."/Action", des)
        table.insert(self.togList, tg)
        table.insert(self.actionList, action)
        -- togList[i] = tg
        UITool.SetLsnrClick(trans, "Togs/Tog"..i, des, self.AwardClick, self)

    end
    UITool.SetBtnClick(trans, "CloseBtn", des, self.Close, self)  

    self:UpAction()
end

--设置监听
function My:SetLnsr(func)
    EvrDayMgr.eDayInfo[func](EvrDayMgr.eDayInfo, self.RespDayInfo, self)
    EvrDayMgr.eGetReward[func](EvrDayMgr.eGetReward, self.RespGetAward, self)
    EvrDayMgr.eGetCountReward[func](EvrDayMgr.eGetCountReward, self.RespGetCount, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action, dic)
    if action==10306 then
        self.dic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.RewardCb, self)
    end
end

--显示奖励回调的方法
function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:UpdateData(self.dic)
    end
end

--每日累充信息
function My:RespDayInfo()
    local dic = self.CountDic
    for i,j in pairs(dic) do
        local cfg = j.cfg
        j:InitCountLab(cfg)
        j:InitBtnState(cfg)
    end
    for k,v in ipairs(EvrDayPayCfg) do
        if k==self.curTp then
            self.EvrPay:InitBtnState(v.id)
        end
    end
end

--领取每日累充奖励
function My:RespGetAward()
    self.EvrPay:HadState()
    self:UpAction()
    self:JumpTabFromGet()
end

--领取每日累计次数奖励
function My:RespGetCount(day)
    -- iTrace.Error("GS","领取每日累计次数奖励   chenggong ")
    self.CountDic[day]:HadState()
end

function My:AwardClick(go)
    local tp = tonumber(string.sub(go.name, 4))
    self:SwitchTg(tp)
end

function My:SwitchTg(tp)
    if self.curTp == tp then return end
    self.curTp = tp
    -- togList[tp].value = true
    self.togList[tp].value = true
    for i,j in ipairs(EvrDayPayCfg) do
        if i==self.curTp then
            self.EvrPay:Init(self.payItem, j, i)
        end
    end
end

function My:InitCountItem()
    local Add = TransTool.AddChild
    for k,v in ipairs(EvrPayCountCfg) do
        local item = Instantiate(self.countItem)
        item:SetActive(true)
        local tran = item.transform
        Add(self.CGrid, tran)
        local temp = ObjPool.Get(UIEvrCountItem)
        temp:Init(tran, v, k)
        local key = v.id
        self.CountDic[key] = temp
    end
end

--icon
function My:UpIcon()
	self:UnloadTex()
	self.iconName = "bg_recharge.png"
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

--跳转到可以领取奖励的分页
function My:JumpTabFromGet()
    local list = {}
    for k,v in pairs(Info.PayAdDic) do
        if v == 2 then
            table.insert(list, k)
        end
    end
    table.sort(list, function(a,b) return a > b end) 
    for i,v in ipairs(list) do
        for k1,v1 in pairs(Info.PayAdDic) do
            if v == k1 then
                local index = self:GetActionIndex(k1)
                self:SwitchTg(index)
                return
            end
        end
    end
    self:SwitchTg(1)
end

--更新红点
function My:UpAction()
    for k,v in pairs(Info.PayAdDic) do
        local index = self:GetActionIndex(k)
        if index ~= nil then
            if v == 2 then
                self:UpShowAction(index, true)
            else
                self:UpShowAction(index, false)
            end
        end
    end
end

--更新显示红点
function My:UpShowAction(index, state)
    local it = self.actionList[index]
    if it then
        it:SetActive(state)
    end
end

--获取红点索引
function My:GetActionIndex(id)
    for i,v in ipairs(EvrDayPayCfg) do
        if id == v.id then
            return i
        end
    end
    return nil
end


--将item放入对象池
function My:ItemToPool()
    for k,v in pairs(self.CountDic) do
        v:Dispose()
    end
  end

function My:OpenCustom()
    -- self:SwitchTg(1)
    self:InitCountItem()
    self:SetLnsr("Add")
    self:JumpTabFromGet()
end

function My:CloseCustom()
    
end

function My.CloseM()
    UIEvrDayPay:Close()
end

function My:Clean()
    self.curTp = nil
    self.payItem = nil
    self.countItem = nil
    self.CGrid = nil
end

function My:DisposeCustom()
    self:UnloadTex()
    if self.EvrPay then
        self.EvrPay:ClearIcon()
        self.EvrPay:Dispose()
        ObjPool.Add(self.EvrPay)
        self.EvrPay = nil
    end
    self:ItemToPool()
    self.dic = nil
    self:Clean()
    self:SetLnsr("Remove")
end

return My