--[[
 	authors 	:Liu
 	date    	:2018-4-9 10:25:40
 	descrition 	:活跃度界面
--]]

UILiveness = UIBase:New{Name = "UILiveness"}

local strs = "UI/UILiveness/"
require(strs.."UIActivityItem")
require(strs.."UIActivityDetail")
require(strs.."UILiveAwardIt")
--周历
require(strs.."UIWeekCalendar")
require(strs.."UIFindBack")

local My = UILiveness

-- 重写基类的初始化方法
function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "Liveness/ActivityBar/Scroll View"

    self.itDic = {}
    self.awardDic = {}
    self.togList = {}
    self.actionList = {}
    self.root = root

    self.sView = CG(UIScrollView, root, str)
    self.title = CG(UILabel,root,"bg2/title",des)
    --self.LXTime = CG(UILabel, root, "bg2/top/GJTimeBg/Label")
    self.lineSize = CG(UISprite, root, "Liveness/LineBg")
    self.Progress = CG(UISlider, root, "Liveness/LineBg/Progress")
    self.panel = CG(UIPanel, root, "Liveness/ActivityBar/Scroll View")
    self.LivenessTotal = CG(UILabel, root, "Liveness/LivenessBg/LivenessCount")

    self.left = Find(root, "left", des)
    self.right = Find(root, "right", des)
    self.zhTran = Find(root,"FindBack",des)
    self.zlTran = Find(root,"UIWeekCalendar",des)
    self.detailTran = Find(root, "ActivityDes", des)
    self.rcCont = Find(root, str.."/RC/Grid", des)
    self.xsCont = Find(root, str.."/XS/Grid", des)
    self.lineBgTran = Find(root, "Liveness/LineBg", des)

    self.item = FindC(root, str.."/RC/Grid/ActivityItem", des)
    self.ActivityBar = FindC(root,"Liveness/ActivityBar",des)
    self.progressGo = FindC(root, "Liveness/LineBg/ProgressLab", des)

    self.top = FindC(root, "bg2/top", des)
    self.bg10 = FindC(root, "bg2/bg10", des)
    self.moduel1 = FindC(root, "Liveness", des)
    self.moduel2 = FindC(root, "FindBack", des)
    self.moduel3 = FindC(root, "UIWeekCalendar", des)

    --SetB(root, "bg2/top/GJTimeBg/PlusBtn", des, self.OnPlusClick, self)
    SetB(root, "CloseBtn", des, self.OnClose, self)
    SetB(root, "Liveness/JumpBtn", des, self.OnJump, self)
    
    self:InitTogs()
    self:SetLXTime()
    self:InitModule()
    self:InitAwardItem()
    self:InitActivItem()
    self:InitActivItemState()
    self:UpLivenessLab()
    self:SetLnsr("Add")
    self:SetMas()
end

--设置监听
function My:SetLnsr(func)
    LivenessMgr.eUpCount[func](LivenessMgr.eUpCount, self.RespUpCount, self)
    LivenessMgr.eUpAward[func](LivenessMgr.eUpAward, self.RespUpAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
    PropMgr.eUse[func](PropMgr.eUse, self.RespUseItem, self)
    FindBackMgr.eBuy[func](FindBackMgr.eBuy, self.SetMas, self)
    FindBackMgr.eFindRed[func](FindBackMgr.eFindRed, self.SetMas, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10304 then		
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

--响应使用离线挂机道具
function My:RespUseItem()
    self:SetLXTime()
end

--响应更新活动次数
function My:RespUpCount(list)
    for i,v in ipairs(list) do
        local it = list[i]
        local id = it.id
        if LivenessInfo.btnIndex == id then
            self:UpShow(id, "UpdateShow")
        end
    end
    self:UpLivenessLab()
end

--响应更新获取奖励
function My:RespUpAward(dic, id)
    if self.awardDic == nil then
        return
    end
    for k,v in pairs(dic) do
        if(self.awardDic[k] ~= nil) then
            self.awardDic[k]:GetedState()
        end
    end
end

--初始化Tog
function My:InitTogs()
    local CG = ComTool.Get
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    for i=1, 4 do
        local path = "Togs/tog"..i
        local tog = CG(UIToggle, self.root, path)
        local mas = FindC(self.root, path.."/mas", self.Name)
        SetS(tog.transform, self.OnTog, self, self.Name)
        table.insert(self.togList, tog)
        table.insert(self.actionList, mas)
    end
    local index = self.index
	local num = (index) and index or 1
    self.togList[num].value = true
    self:SwitchMenu(num)
end

--点击Tog
function My:OnTog(go)
    local num = tonumber(string.sub(go.name, 4))
    if num <= 2 then
        self:ReSetPanel()
    end
    self:SwitchMenu(num)
    self.detail:SetMenuState(false)
end

--切换界面
function My:SwitchMenu(index)
    local str = ""
    if index == 1 then
        str = "日常活动"
        self:SetModuelState(true, true, true, false, false)
    elseif index == 2 then
        str = "限时活动"
        self:SetModuelState(true, true, true, false, false)
    elseif index == 3 then
        if self.zh == nil then
            self.zh = ObjPool.Get(UIFindBack)
            self.zh:Init(self.zhTran)
        end
        str = "资源找回"
        self:SetModuelState(true, false, false, true, false)
        FindBackMgr.OpenChangeOver()
    elseif index == 4 then
        if self.zl == nil then
            self.zl = ObjPool.Get(UIWeekCalendar)
            self.zl:Init(self.zlTran)
        end
        str = "活动周历"
        self:SetModuelState(false, false, false, false, true)
    end
    self.title.text = str
end

--设置模块状态
function My:SetModuelState(state1, state2, state3, state4, state5)
    self.top:SetActive(state1)
    self.bg10:SetActive(state2)
    self.moduel1:SetActive(state3)
    self.moduel2:SetActive(state4)
    self.moduel3:SetActive(state5)
end

--点击增加离线挂机时间按钮
function My:OnPlusClick()
    OffRwdMgr:Addtime()
end

--红点
function My:SetMas()
    if FindBackMgr.Red then
        self.actionList[3]:SetActive(true);
    else
        self.actionList[3]:SetActive(false);
    end
end

--初始化模块
function My:InitModule()
    self.detail = ObjPool.Get(UIActivityDetail)
    self.detail:Init(self.detailTran)

    -- local OG = ObjPool.Get
    -- self.zl = OG(UIWeekCalendar)
    -- self.zl:Init(self.zlTran)

    -- self.zh = OG(UIFindBack)
    -- self.zh:Init(self.zhTran)
end

--初始化活动项
function My:InitActivItem()
    local AddC = TransTool.AddChild
    for i, v in ipairs(LivenessCfg) do
        local go = Instantiate(self.item)
        local tran = go.transform
        go:SetActive(true)
        local it = ObjPool.Get(UIActivityItem)
        it:Init(tran, v)
        local parent = (v.type==1) and self.rcCont or self.xsCont
        AddC(parent, tran)
        local key = tostring(v.id)
        self.itDic[key] = it
    end
    self.item:SetActive(false)
end

--根据按钮索引更新显示
function My:UpShow(id, func)
    local key = tostring(id)
    local dic = self.itDic
    local it = dic[key]
    if it then
        it[func](it)
    end
end

--初始化活动项状态
function My:InitActivItemState()
    self:SetState(self.itDic)
end

--设置活动项状态
function My:SetState(dic)
    for k,v in pairs(dic) do
        if v.cfg.type == 1 then
            v:SetBtnState()
        elseif v.cfg.type == 2 then
            v:UpActivState()
            v:UpBtnState()
        end
    end
end

--更新活跃度
function My:UpLivenessLab()
    local cfg = LivenessAwardCfg
    local total = cfg[#cfg].id
    local liveness = LivenessInfo.liveness
    local val = (liveness >= total) and total or liveness
    self.LivenessTotal.text = val   
    self.Progress.value = self:LineBgProValue(val)
    self:UpAwardState(self.awardDic, false)
end

--计算进度条
function My:LineBgProValue(value)
    local val = 0;
    local valid = 0;
    local cfg = LivenessAwardCfg;
    for i=1,#cfg do
        if ( value <= cfg[i].id ) then
            valid = i;
            break;
        end
    end
    if valid == 1 then
        val = value * (1/#cfg) / (cfg[valid].id) - 0.05;
        if (val < 0) then
            val = 0;
        end
    elseif valid == #cfg then
        val = (1/#cfg)*(valid-1) + (value - cfg[valid-1].id)*(1/#cfg) / (cfg[valid].id -cfg[valid-1].id);
    else
        val = (1/#cfg)*(valid-1) + (value - cfg[valid-1].id)*(1/#cfg) / (cfg[valid].id -cfg[valid-1].id) - 0.05;
    end
    return val;
end

--更新奖励颜色
function My:UpAwardState(dic, state)
    for k,v in pairs(dic) do
        v:BrightState()
    end
end

--创建奖励物品
function My:InitAwardItem()
    local AddC = TransTool.AddChild
    local cfg = LivenessAwardCfg
    local item = self.progressGo
    local Xpos = self.lineSize.width / #cfg
    local yPos = item.transform.localPosition.y
    local itemPos = Vector3.New(0, yPos, 0)
    for i,v in ipairs(cfg) do
        local go = Instantiate(item)
        local tran = go.transform
        AddC(self.lineBgTran, tran)
        itemPos.x = (Xpos * i) - 30
        tran.localPosition = itemPos
        local it = ObjPool.Get(UILiveAwardIt)
        it:Init(tran, v)
        local key = tostring(v.id)
        self.awardDic[key] = it
    end
    item:SetActive(false)
end

--设置离线挂机时间
function My:SetLXTime()
    --self.LXTime.text = OffRwdMgr.GetHaveOffLineTime()
end

--设置描述坐标
function My:SetDesPos(pos)
    local Add = TransTool.AddChild
    local it = self.detail
    it:SetMenuState(true)
    if pos > 100 then
        Add(self.right, it.root)
    else
        Add(self.left, it.root)
    end
end

--重置Panel
function My:ReSetPanel()
    self.sView:ResetPosition()
end

--1.日常活跃
--2.限时活动
--3.资源找回
--4.活动周历
function My:OpenTab(index)
	self.index = index
    UIMgr.Open(UILiveness.Name)
    -- if id then self:OpenSelect(id) end
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.index = t1
end

-- --打开界面时的默认选择
-- function My:OpenSelect(id)
--     local key = tostring(id)
--     self.itDic[key].tog.value = true
--     if LivenessMgr:IsComplete(id) then
--         self:SetSView()
--     end
-- end

-- --设置Scroll View
-- function My:SetSView()
-- 	self.panel.transform.localPosition = Vector3.New(0, 139, 0)
-- 	self.panel.clipOffset = Vector2.New(0, -139)
-- end

--跳转到商城
function My:OnJump()
    StoreMgr.OpenStore(99)
end

--点击关闭
function My:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

--清理缓存
function My:Clear()
    if self.zl~=nil then
        self.zl:Clear();
    end
    if self.zh~=nil then
        self.zh:Clear();
    end
end

--重写释放资源
function My:DisposeCustom()
    self.dic = nil
    self.index = nil
    ObjPool.Add(self.detail)
    self.detail = nil
    ObjPool.Add(self.zh)
    self.zh = nil
    ObjPool.Add(self.zl)
    self.zl = nil
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.awardDic)
    TableTool.ClearDicToPool(self.itDic)
end

return My

