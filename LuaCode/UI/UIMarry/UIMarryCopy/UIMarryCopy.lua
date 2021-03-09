--[[
 	authors 	:Liu
 	date    	:2018-12-18 19:16:00
 	descrition 	:结婚副本
--]]

UIMarryCopy = UIBase:New{Name = "UIMarryCopy"}

local My = UIMarryCopy

local AssetMgr = Loong.Game.AssetMgr

require("UI/UIMarry/UIMarryCopy/UIMarryCopyWish")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.progress = CG(UISlider, root, "moduel1/progress")
    self.progressLab = CG(UILabel, root, "moduel1/progress/lab")
    self.btnLab1 = CG(UILabel, root, "Info/btn1/lab")
    self.btnLab2 = CG(UILabel, root, "Info/btn2/lab")
    self.lab1 = CG(UILabel, root, "Info/lab1")
    self.lab2 = CG(UILabel, root, "Info/lab2")
    self.lab3 = CG(UILabel, root, "Info/lab3")
    self.item1 = Find(root, "Info/item1", des)
    self.item2 = Find(root, "Info/item2", des)
    self.wishTran = Find(root, "moduel2", des)

    self.grid = CG(UIGrid, root, "Grid")
    self.btn1Lab = CG(UILabel, root, "Grid/btn1/timeLab")
    self.btn2Lab = CG(UILabel, root, "Grid/btn2/timeLab")
    self.timeCount = CG(UILabel, root, "ExitTip/timeCount")
    self.heatLab = CG(UILabel, root, "heatBg/lab")
    self.collLab = CG(UILabel, root, "autoBtn/lab")
    self.btn1 = FindC(root, "Grid/btn1", des)
    self.btn2 = FindC(root, "Grid/btn2", des)
    self.exitTip = Find(root, "ExitTip", des)
    self.exitBtn = FindC(root, "exitBtn", des)
    self.heatBg = FindC(root, "heatBg", des)
    self.action = FindC(root, "moduel1/btn3/action")
    self.autoEff = FindC(root, "autoBtn/AutoEff", des)
    self.autoBtn = FindC(root, "autoBtn", des)

    if ScreenMgr.orient == ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(root, "Info", name, true)
    end

    self.candiesId = 100101
    self.idList = {31039, 31040}
    self.cellList = {}
    self.btn1Time = 0
    self.btn2Time = 0
    self.heatTime = 0
    self.filterName = ""
    --true:可以采集
    self.canCollect = false
    --是否自动采集
    self.isAutoCollect = false

    CollectMgr:SetStop(false)

    SetB(root, "Info/btn1", des, self.OnBuyOrUse1, self)
    SetB(root, "Info/btn2", des, self.OnBuyOrUse2, self)
    SetB(root, "moduel1/btn1", des, self.OnBtn1, self)
    SetB(root, "moduel1/btn2", des, self.OnBtn2, self)
    SetB(root, "moduel1/btn3", des, self.OnBtn3, self)
    SetB(root, "moduel1/btn4", des, self.OnBtn4, self)
    SetB(root, "autoBtn", des, self.OnAutoCollect, self)
    SetB(root, "exitBtn", des, self.OnExit, self)

    self:InitItems()
    self:UpItemCount()
    self:UpBtnLab()

    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eExp[func](MarryMgr.eExp, self.RespExp, self)
    MarryMgr.eMapInfo[func](MarryMgr.eMapInfo, self.RespMapInfo, self)
    MarryMgr.eHeat[func](MarryMgr.eHeat, self.RespHeat, self)
    MarryMgr.eHeatShow[func](MarryMgr.eHeatShow, self.RespHeatShow, self)
    MarryMgr.eTaset[func](MarryMgr.eTaset, self.RespTaset, self)
    MarryMgr.eCandyTime[func](MarryMgr.eCandyTime, self.RespCandyTime, self)
    MarryMgr.eUpCandyCount[func](MarryMgr.eUpCandyCount, self.RespUpCandyCount, self)
    MarryMgr.eUpAction[func](MarryMgr.eUpAction, self.RespUpAction, self)
    MarryMgr.eFireworks[func](MarryMgr.eFireworks, self.RespFireworks, self)
    --其他事件监听
    StoreMgr.eBuyResp[func](StoreMgr.eBuyResp, self.RespBuy, self)
    UIMainMenu.eHide[func](UIMainMenu.eHide, self.RespBtnHide, self)
    UIMainMenu.eOpen[func](UIMainMenu.eOpen, self.RespMenuOpen, self)
    PropMgr.eUpdate[func](PropMgr.eUpdate, self.RespUse, self)

    CollectMgr.eRespBeg[func](CollectMgr.eRespBeg, self.RespRespBeg, self)
    CollectMgr.eRespEnd[func](CollectMgr.eRespEnd, self.RespEnd, self)
    CollectMgr.einterupt[func](CollectMgr.einterupt, self.RespInterupt, self)
    ScreenMgr.eChange[func](ScreenMgr.eChange, self.ScrChg, self)
    Hangup.eUpdateAutoStatus[func](Hangup.eUpdateAutoStatus, self.RespUpdateAutoStatus, self)
    NavPathMgr.eNavPathEnd[func](NavPathMgr.eNavPathEnd,self.NavPathEnd,self)
    euiopen[func](euiopen,self.OpenCb,self)
    
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "Info", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "Info", nil, true, true)
	end
end

--检测是否正在挂机
function My:RespUpdateAutoStatus()
    if self.isAutoCollect then
        self.isAutoCollect = not self.isAutoCollect
        self:StopCollect()
    end
    if not Hangup:GetSituFight() then
        Hangup:SetSituFight(true)
    end
    local list = User:FindAllBoss()
    local count = list.Count
    if count > 0 then
        -- User:StartNavPath(Vector3.New(0, 0, 25), 30019, -1, 0)
        SelectRoleMgr.instance:StartNavPath(list[0], 1)
    end
end

--响应播放烟花
function My:RespFireworks(id)
    for i,v in ipairs(self.idList) do
        if v == id then
            self:CreatePrefab(id)
        end
    end
end

--响应更新红点
function My:RespUpAction()
    self:UpAction()
end

--响应主界面打开
function My:RespMenuOpen()
    UIMainMenu.LeftView.GO:SetActive(false)
end

--响应开始采集
function My:RespRespBeg(err, uid, dur)
    if err == 10402006 then--刷新采集物，采集中断
        if self.isAutoCollect then
            UITip.Log("采集物刷新")
            self:AutoCollection(true)
        end
    elseif err == 10402003 then--多人采集，采集中断
        self:AutoCollection(true)
    end
end

--响应采集结束
function My:RespEnd(err,uid)
    if err > 0 then
        return
    end
    if not self:IsAutoCollection() then
        UITip.Log("当前可采集次数已满")
        self:StopCollect()
        return
    end
    if self.isAutoCollect then
        self.filterName = tostring(uid)
        self:AutoCollection()
    end
end

--响应采集中断
function My:RespInterupt()
    if self.isAutoCollect then
        self:OnAutoCollect()
    end
end

--响应更新喜糖次数
function My:RespUpCandyCount(count)
    if count > 0 then
        self:ResetCollect(2)
    else
        self:FilterCollect(true)
    end
end

--响应天降喜糖
function My:RespCandyTime()
    self:UpBtn2()
end

--响应品尝美食
function My:RespTaset()
    self:UpLab2()
end

--更新热度
function My:RespHeat(heat)
    self:UpHeat(heat)
end

--更新热度显示
function My:RespHeatShow(heat)
    self:SetHeatShow(true, heat)
end

--响应使用道具
function My:RespUse()
    self:UpItemCount()
    self:UpBtnLab()
end

--响应隐藏按钮
function My:RespBtnHide(value)
    self.exitBtn:SetActive(value)
    self.autoBtn:SetActive(value)
    if self.btn1Time > 0 then
        self.btn1:SetActive(value)
    end
end

--响应副本信息
function My:RespMapInfo()
    self:CreateTimer()
    self:InitExitTip()
    self:UpBtn1()
    self:UpBtn2()
    self:UpLab1()
    self:UpLab2()
    self:InitHeat()
    self:UpAction()

    -- UIMainMenu:HideLeftView()
    UIMainMenu.LeftView.GO:SetActive(false)
end

--响应更新经验
function My:RespExp(exp)
    local count = CustomInfo:ConvertNum(tonumber(exp))
    local txt = string.format("[FFE9BDFF]获得经验：[F9A7B9FF]%s", count)
    self.lab3.text = txt
end

--响应购买
function My:RespBuy()
    self:UpItemCount()
    self:UpBtnLab()
end

--初始化道具
function My:InitItems()
    for i,v in ipairs(self.idList) do
        local cell = ObjPool.Get(UIItemCell)
        local parent = (i == 1) and self.item1 or self.item2
        cell:InitLoadPool(parent, 0.7)
        table.insert(self.cellList, cell)
    end
end

--更新道具数量
function My:UpItemCount()
    for i,v in ipairs(self.idList) do
        local cell = self.cellList[i]
        local count = ItemTool.GetNum(v)
        local str = ""
        if count < 1 then
            str = string.format("[FF0000FF]%s[00FF00FF]/1", count)
        else
            str = string.format("[00FF00FF]%s/1", count)
        end
        cell:UpData(v, str)
    end
end

--更新购买按钮的文本
function My:UpBtnLab()
    for i,v in ipairs(self.idList) do
        local count = ItemTool.GetNum(v)
        local str = (count > 0) and "使用" or "购买"
        local lab = (i == 1) and self.btnLab1 or self.btnLab2
        lab.text = str
    end
end

--更新拜堂时间文本
function My:UpLab1()
    local rTime = MarryInfo:GetBowTime()
    local str = (rTime > 0) and "即将开始" or "拜堂结束"
    local txt = string.format("[FFE9BDFF]婚礼拜堂：[F9A7B9FF]%s", str)
    self.lab1.text = txt
end

--更新品尝美食文本
function My:UpLab2()
    local cfg = GlobalTemp["65"]
    if cfg then
        local count = MarryInfo.mapData.tasetCount
        local txt = string.format("[FFE9BDFF]品尝美食：[F9A7B9FF]%s/%s", count, cfg.Value3)
        self.lab2.text = txt
        self:FilterCollect(false, count)
    end
end

--过滤采集
function My:FilterCollect(IsCandies, count)
    if IsCandies then
        CollectMgr.AddFilter(self.candiesId)
    else
        if count > 9 then
            local cfg = GlobalTemp["65"]
            if cfg == nil then return end
            for i,v in ipairs(cfg.Value2) do
                CollectMgr.AddFilter(v)
            end
        end
    end
end

--重置采集
function My:ResetCollect(index)
    if index == nil then return end
    if index == 1 then
        local cfg = GlobalTemp["65"]
        if cfg == nil then return end
        for i,v in ipairs(cfg.Value2) do
            CollectMgr.RemoveFilter(v)
        end
    elseif index == 2 then
        CollectMgr.RemoveFilter(self.candiesId)
    end
end

--点击购买/使用道具1
function My:OnBuyOrUse1()
    local text = self.btnLab1.text
    if text == "购买" then
        UIMarryInfo:OpenStore()
    elseif text == "使用" then
        self:UseItem(self.idList[1])
    end
end

--点击购买/使用道具2
function My:OnBuyOrUse2()
        local text = self.btnLab2.text
    if text == "购买" then
        UIMarryInfo:OpenStore()
    elseif text == "使用" then
        self:UseItem(self.idList[2])
    end
end

--使用道具
function My:UseItem(id)
    local mgr = PropMgr
    local uid = mgr.TypeIdById(id)
    if uid == nil then return end
    mgr.ReqUse(uid, 1)
end

--创建特效
function My:CreatePrefab(id)
    self:ClearEff()
    local str = (id==31039) and "fx_yanhua01" or "fx_yanhua02"
    AssetMgr.LoadPrefab(str, GbjHandler(self.LoadPrefabCb, self))
end

--加载特效回调
function My:LoadPrefabCb(eff)
    local parent = Camera.main.transform
    eff.transform.parent = parent
    local pPos = FindHelper.instance:GetOwnerPos()
    if eff.name == "fx_yanhua01" then
        eff.transform.localPosition = Vector3.New(0.95, 0.66, 8.41)
        eff.transform.localRotation = Quaternion.Euler(-24,56,-26)
    else
        eff.transform.localPosition = Vector3.New(0, 0.14, 4.8)
        eff.transform.localRotation = Quaternion.Euler(-34,-4,-2.5)
    end
    self.eff = eff
end

--点击祝福
function My:OnBtn1()
    self:InitModuel()
end

--点击婚宴商店
function My:OnBtn2()
    UIMarryInfo:OpenStore()
end

--点击宾客管理
function My:OnBtn3()
    if MarryInfo:IsFeastRole() then
        UIProposePop:OpenTab(6, true)
    else
        UITip.Log("只有婚礼举办者才能管理宾客")
    end
end

--点击热度说明
function My:OnBtn4()
    local cfg = InvestDesCfg["1025"]
    if cfg == nil then return end
    UIComTips:Show(cfg.des, Vector3.New(0, -93, 0), nil, nil, nil, nil, nil, "xn_ty_04B")
end

--初始化热度
function My:InitHeat()
    local heat = MarryInfo.mapData.heat
    self:UpHeat(heat)
end

--更新热度
function My:UpHeat(heat)
    local max = MarryInfo:GetHeatMax()
    if max == nil or max == 0 then return end
    local labMax = self:GetHeatMaxNow(heat)
    self.progress.value = heat / max
    self.progressLab.text = heat.."/"..labMax
end

--获取当前热度上限
function My:GetHeatMaxNow(heat)
    local cfg = GlobalTemp["62"]
    if cfg then
        local valList = cfg.Value2
        if valList[1] >= heat then
            return valList[1]
        elseif valList[2] >= heat then
            return valList[2]
        else
            return valList[3]
        end
    end
end

--更新拜堂按钮
function My:UpBtn1()
    local rTime = MarryInfo:GetBowTime()
    if rTime > 0 then
        self.btn1Time = rTime
        self.btn1:SetActive(true)
        self.grid:Reposition()
    end
end

--更新拜堂按钮倒计时
function My:UpBtn1Lab()
    if self.btn1Time < 0.01 then return end
    local timer = self.timer
    if timer.cnt <= self.btn1Time then
        local rs = self.btn1Time - timer.cnt
        local remain =  DateTool.FmtSec(rs, timer.fmtOp, timer.apdOp)
        self.btn1Lab.text = remain
    else
        if not MarryInfo.isAnim then
            CollectMgr:SetStop(true)
            MarryInfo.isAnim = true
            self.btn1Time = 0
            SceneMgr:ReqPreEnter(30020, false, true)
            return
        end
        self.btn1:SetActive(false)
        self.lab1.text = "[FFE9BDFF]婚礼拜堂：[F9A7B9FF]拜堂结束"
        self.grid:Reposition()
    end
end

--更新天降喜糖按钮
function My:UpBtn2()
    local rTime = MarryInfo:GetCandyTime()
    if rTime > 0 then
        self.btn2Time = rTime
        self.btn2:SetActive(true)
        self.grid:Reposition()
    end
end

--更新天降喜糖按钮倒计时
function My:UpBtn2Lab()
    if self.btn2Time < 0.01 then return end
    local timer = self.timer
    if timer.cnt <= self.btn2Time then
        local rs = self.btn2Time - timer.cnt
        local remain =  DateTool.FmtSec(rs, timer.fmtOp, timer.apdOp)
        self.btn2Lab.text = remain
    else
        self.btn2:SetActive(false)
        self.grid:Reposition()
    end
end

--初始化副本剩余时间
function My:InitExitTip()
    local info = MarryInfo
    local times = info.mapData.bowETime
    local rTime = info:SwitchTime(times)
    if rTime > 0 then
        self:UpTimer(rTime)
        self.exitTip.gameObject:SetActive(true)
    end
end

--更新计时器
function My:UpTimer(rTime)
	if self.timer == nil then return end
	local timer = self.timer
	timer.seconds = rTime
	timer:Start()
	self:InvCountDown()
end

--创建计时器
function My:CreateTimer()
	if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()
    if self.timeCount then
        self.timeCount.text = self.timer.remain
        self:UpBtn1Lab()
        self:UpBtn2Lab()
        self:UpHeatState()
        -- self:UpInteruptTime()
    end
end

--结束倒计时
function My:EndCountDown()
    self.exitTip.gameObject:SetActive(false)
end

--初始化祝福模块
function My:InitModuel()
    if self.wish == nil then
        self.wish = ObjPool.Get(UIMarryCopyWish)
        self.wish:Init(self.wishTran)
    end
    self.wish:UpShow(true)
end

--设置热度显示
function My:SetHeatShow(state, count)
    local str = ""
    if count >= 3344 then
        str = string.format("热度达到%s快去打Boss吧", count)
    else
        str = string.format("热度达到%s快去抢喜糖吧", count)
    end
    self.heatBg:SetActive(state)
    self.heatLab.text = str
    self.heatTime = 3
end

--更新热度状态
function My:UpHeatState()
    if self.heatTime > 0 then
        self.heatTime = self.heatTime - 1
    else
        self:SetHeatShow(false, 0)
    end
end

--是否能自动采集
function My:IsAutoCollection()
    local info = MarryInfo.mapData
    local tasetCount = info.tasetCount
    local remainCount = info.remainCount
    if remainCount > 0 then
        return true
    elseif tasetCount < 10 then
        return true
    end
    return false
end

--自动采集
function My:AutoCollection(isPass)
    if isPass == nil then isPass = false end
    if not isPass then
        if(CollectMgr.state == CollectState.Running) then return end
        if(CollectMgr.state == CollectState.Interupt) then return end
    end

    local info = MarryInfo.mapData
    local tasetCount = info.tasetCount
    local remainCount = info.remainCount
    local goList = {}
    if remainCount > 0 then
        local id = self.candiesId
        local go = User.instance:GetNearestColl(id, self.filterName, isPass)
        if (go~=nil) then
            self:SetCollect(go)
            return
        end
    elseif tasetCount < 10 then
        local cfg = GlobalTemp["65"]
        if cfg == nil then return end
        for i,v in ipairs(cfg.Value2) do
            local go = User.instance:GetNearestColl(v, self.filterName, isPass)
            if go ~= nil then
                table.insert(goList, go)
            end
        end
        local pPos = FindHelper.instance:GetOwnerPos()
        if #goList > 0 then
            table.sort(goList, function(a,b) return (a.transform.position - pPos).sqrMagnitude < (b.transform.position - pPos).sqrMagnitude end)
            self:SetCollect(goList[1])
        end
    end
end

--设置采集
function My:SetCollect(go)
    local pos = go.transform.position;
    local changePos = MapHelper.instance:GetCanStandPos(pos, 1);
    local pPos = FindHelper.instance:GetOwnerPos()
    local dis = Vector3.Distance(pPos, changePos)
    if dis < 1 then
        CollectMgr.ReqBeg()
    else
        self:NavPathStart(changePos)
    end
    self.collLab.text = "采集中"
    self.autoEff:SetActive(true)
end

--自动寻路开始
function My:NavPathStart(pos)
    User:StartNavPath(pos, 30019, -1, 0)
end

--响应寻路结束
function My:NavPathEnd(type, missId)
    if type ~= 2 then
        if self.isAutoCollect then
            self:OnAutoCollect()
        end
    else
        local at = UIMgr.GetActive(UICollection.Name)
        if at==1 then
            CollectMgr.ReqBeg()
            self.canCollect = false
        else
            self.canCollect = true
        end
    end
end

--点击自动采集
function My:OnAutoCollect()
    if Hangup:GetSituFight() or Hangup:GetAutoHangup() then
        UITip.Log("自动挂机中，不能采集")
        return
    end
    local isCanCollect = self:IsCanCollect()
    if not isCanCollect then
        UITip.Log("当前场景中没有采集物")
        return
    end
    if not self:IsAutoCollection() then
        UITip.Log("当前可采集次数已满")
        return
    end
    self.isAutoCollect = not self.isAutoCollect
    if self.isAutoCollect then
        self:AutoCollection()
    else
        self:StopCollect()
    end
end

--终止采集
function My:StopCollect()
    self.collLab.text = "采集"
    User:StopNavPath()
    CollectMgr:ReqStop()
    self.autoEff:SetActive(false)
end

--判断是否存在采集物
function My:IsExistCollect()
    local cfg = GlobalTemp["65"]
    if cfg == nil then return end
    local count = 0
    local list = {}
    for i,v in ipairs(cfg.Value2) do
        table.insert(list, v)
    end
    table.insert(list, self.candiesId)
    for i,v in ipairs(list) do
        local go = User.instance:GetNearestColl(v, self.filterName)
        if go then
            count = count + 1
        end
    end
    return count
end

--判断是否能采集
function My:IsCanCollect()
    local count = self:IsExistCollect()
    local rTime = self.timer:GetRestTime()
    if count > 0 then
        return true
    end
    if (MarryInfo.feastTotalTime - rTime < 60) then
        return false
    end
    return true
end

--UI打开的回调
function My:OpenCb(name)
    if self.canCollect == false then return end
    self.canCollect = false
    CollectMgr.ReqBeg()
end

--点击退出按钮
function My:OnExit()
	MsgBox.ShowYesNo("是否退出场景？", self.YesCb, self)
end

--点击确定按钮
function My:YesCb()
    SceneMgr:QuitScene()
end

--更新红点
function My:UpAction()
    if MarryInfo:IsFeastRole() then
        self.action:SetActive(MarryInfo.isShowAction)
    end
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清空特效
function My:ClearEff()
    if self.eff then
        Destroy(self.eff)
        self.eff = nil
    end
end

--清空计时器
function My:ClearTimer()
    if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
    end
end

--清理缓存
function My:Clear()
    CollectMgr:SetStop(false)
    self.isAutoCollect = false
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:ClearTimer()
    if self.wish then
        ObjPool.Add(self.wish)
        self.wish = nil
    end
    TableTool.ClearListToPool(self.cellList)
    self:SetLnsr("Remove")
    self:ResetCollect(1)
    self:ResetCollect(2)
end

return My