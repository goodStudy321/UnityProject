--[[
 	authors 	:Liu
 	date    	:2018-5-22 09:55:40
 	descrition 	:冲级豪礼合集模块
--]]

UILvAward = UIBase:New{Name = "UILvAward"}

local My = UILvAward

require("UI/UILvAward/UILvAwardMenu")
require("UI/UILvAward/UIOffLineShow")
require("UI/UILvAward/UIGdAward")
require("UI/UISign/UISign")
require("UI/Seven/UISeven")
require("UI/UIActiveCode/UIActiveCode")
require("UI/UIPray/UIPrayPanel")
require("UI/EvrBox/UIEvrBox")
require("RedPacketActiv/UIRedPacketActiv");

My.eSwitch = Event()

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local CG=ComTool.Get
    self.Grid=CG(UIGrid,root,"ActivModule/Grid",des)
    self.modDic = {}
    self.togDic = {}
    self.actionDic = {}
    self.strDic = {}
    self.modInfoDic = {}
    self.curIndex = 0

    self.strDic["1"] = "冲级豪礼"
    local module1 = Find(root, "GiftModule", des)
    self:SetModInfo(module1, UILvAwardMenu, 1)

    if not SignMgr.isOpen and LivenessInfo:IsOpen(1002) then
        self.strDic["2"] = "七日登录"
        local module2 = Find(root, "SevenModule", des)
        self:SetModInfo(module2, UISeven, 2)
    elseif SignMgr.isOpen then
        self.strDic["3"] = "每日签到"
        local module3 = Find(root, "SignModule", des)
        self:SetModInfo(module3, UISign, 3)
    end

    

    -- self.strDic["4"] = "好评奖励"
    -- local module4 = Find(root, "gdModule", des)
    -- self:SetModInfo(module4, UIGdAward, 4)

    -- if PrayMgr:IsOpen() then
    --     self.strDic["5"] = "闭关修炼"
    --     local module5 = Find(root, "prayModule", des)
    --     self:SetModInfo(module5, UIPrayPanel, 5)
    -- end

    -- if OffRwdMgr.UIisOpen() then
    --     self.strDic["6"] = "离线奖励"
    --     local module6 = Find(root,"UIOffLineShow")
    --     self:SetModInfo(module6, UIOffLineShow, 6)
    -- end

    if not ShieldEntry.ShieldGbj(ShieldEnum.ActivationCode) then
        self.strDic["7"] = "礼包兑换"
        local module7 = Find(root, "activeCode", des)
        self:SetModInfo(module7, UIActiveCode, 7)
    end

    if EvrBoxMgr:IsOpen() then
        self.strDic["8"] = "每日宝箱"
        local module8 = Find(root, "DayBoxM", des)
        self:SetModInfo(module8, UIEvrBox, 8)
    end
    
    if NewActivMgr:ActivIsOpen(2011) then
    --if true then
        self.strDic["9"] = "全服红包";
        local module9 = Find(root, "UIRedPacketActiv", des);
        self:SetModInfo(module9, UIRedPacketActiv, 9);
    end


    self.tog = FindC(root, "ActivModule/Grid/tog1", des)

    SetB(root, "CloseBtn", des, self.OnClose, self)

    self:SetLnsr("Add")

    local index = (self.index==nil) and 1 or self.index
    if self.index == nil then self:OpenTab(index) end

end

--设置监听
function My:SetLnsr(func)
    LvAwardMgr.eUpAction[func](LvAwardMgr.eUpAction, self.UpAction, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10016 or action==10017 or action==10018 or action==10019 or action == 10421 then		
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

--更新红点
function My:UpAction()
    local dic = self.actionDic
	if dic == nil then return end
    for k,v in pairs(LvAwardMgr.actionDic) do
        local go = dic[k]
        if go then
            go:SetActive(v)
        end
	end
end

--初始化Togs
function My:InitTogs()
    if self.tog == nil then self:Close() return end
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local Add = TransTool.AddChild
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    local parent = self.tog.transform.parent
    for k,v in pairs(self.strDic) do
        local go = Instantiate(self.tog)
        local tran = go.transform
        go.name = k
        local red = FindC(tran, "Action", self.Name)
        local lab1 = CG(UILabel, tran, "Label")
        local lab2 = CG(UILabel, tran, "Label1")
        local tog = CGS(UIToggle, tran, self.Name)
        lab1.text = v
        lab2.text = v
        Add(parent, tran)
        SetS(tran, self.OnTog, self, self.Name)
        self.actionDic[k] = red
        self.togDic[k] = tog
    end
    local index = self.index
	local num = (index and self.togDic[index]) and index or "1"
	self.togDic[num].value = true
    self:SwitchMenu(num)
    self.tog:SetActive(false)
    self.Grid:Reposition()
    -- ShieldEntry.ShieldGbj( ShieldEnum.ActivationCode ,self.togDic["7"].gameObject)
end

--点击Tog
function My:OnTog(go)
    self:SwitchMenu(go.name)
    My.eSwitch()
end

--设置界面状态
function My:SwitchMenu(key)
    if self.curIndex == key then return end
    local k = tostring(key)
    if self.modDic[k] == nil then
        local info = self.modInfoDic[k]
        if info == nil then return end
        self:InitModule(info.tran, info.obj, info.key)
    end
    for k,v in pairs(self.modDic) do
        if k == key then
            v:UpShow(true)
        else
            v:UpShow(false)
        end
    end
    self.curIndex = key
end

--初始化模块
function My:InitModule(module, class, index)
    local key = tostring(index)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    self.modDic[key] = mod
end

--设置模块信息
function My:SetModInfo(tran, obj, key)
    local info = {}
    info.tran = tran
    info.obj = obj
    info.key = key
    self.modInfoDic[tostring(key)] = info
end

--更新
function My:Update()
    if self.modDic["1"] then
        self.modDic["1"]:Update()
    end
    if self.modDic["9"] then
        self.modDic["9"]:Update();
    end
end

--1.冲级豪礼
--2.七日登陆
--3.每日签到
--4.好评奖励
--5.祈福
--6.离线奖励
--7.礼包兑换
--8.每日宝箱
--9.全服红包
function My:OpenTab(index)
    self.index = tostring(index)
    UIMgr.Open(UILvAward.Name)
    self:InitTogs()
    self:UpAction()
end

--特殊的打开方式
function My:GetSpecial(t1)
    if t1 == 5 then
        local isOpen = PrayMgr:IsOpen()
        if not isOpen then
            UITip.Log("系统未开启")
        end
        return isOpen
    end
    return true
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.index = tostring(t1)
    self:InitTogs()
    self:UpAction()
end

--关闭界面
function My:OnClose()
	self:Close()
	JumpMgr.eOpenJump()
end

--清理缓存
function My:Clear()
    self.index = nil
    self.dic = nil
    self.curIndex = 0
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.modDic)
    TableTool.ClearDic(self.modInfoDic)
end

return My