require("UI/Robbery/StateSInfo")
require("UI/Robbery/StatePInfo")
require("UI/Robbery/MissionPanel")
require("UI/Robbery/StateExpInfo")
require("UI/Robbery/StateModInfo")
require("UI/Robbery/StateSkillTip")
require("UI/Robbery/StatePTotal")
require("UI/UIPray/UIPrayPanel") --闭关修炼

StatePanel = UILoadBase:New{Name = "StatePanel"}
local My = StatePanel

function My:Init()
    local root = self.GbjRoot.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local US = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild
    root = TF(root,"trans",name)
    local stateS = TFC(root,"StateInfo/stateS",name)
    local stateP = TFC(root,"stateP",name)
    local missionP = TF(root,"StateInfo/missionP",name)
    self.expP = TF(root,"expP",name)
    self.prayM = TF(root,"prayModule",name)
    self.roInfo = self.robInfo

    self.modelRoot = TFC(root,"modelRoot",name)
    self.modelCam = TFC(root,"modelRoot/modCam",name)
    self.ruBtnG = CG(BoxCollider,root,"StateInfo/rBtn")
    self.roLab = CG(UILabel,root,"StateInfo/rBtn/lab",name)
    self.roLab1 = CG(UILabel,root,"StateInfo/rBtn/lab1",name)
    self.timeLab = CG(UILabel,root,"StateInfo/rBtn/lab1/timeLab",name)
    self.ruBtnEffect = TFC(root,"StateInfo/rBtn/FX_UI_Button",name)
    self.consumeGbj = TFC(root,"StateInfo/consume",name)
    self.propTexture = CG(UITexture,root,"StateInfo/consume/propT",name)
    self.bgTexture = CG(UITexture,root,"bg",name)
    self.praceLab = CG(UILabel,root,"StateInfo/consume/pracLab",name)
    self.fightLab = CG(UILabel,root,"fightLab",name)
    -- self.fightBox = CG(BoxCollider,root,"fightLab")
    self.desBtn = CG(BoxCollider, root,"desBtn", name,true)
    self.prayBtnG = TFC(root,"pryBtn",name)
    self.pryLab = CG(UILabel,root,"pryBtn/lab",name)
    self.curStateLab = CG(UILabel,root,"curName/lab",name)
    self.prySp = CG(UIButton,root,"pryBtn",name)
    self.curStateSp = CG(UIButton,root,"curName",name)
    
    self.spBtn = CG(BoxCollider,root,"spBtn",name)
    self.spRed = TFC(root,"spBtn/red",name)

    local propP = TF(root,"propP",name)
    self.statePTAct = ObjPool.Get(StatePTotal)
    self.statePTAct:Init(propP)

    local skilTip = TF(root,"tips")
    self.stateSkillT = ObjPool.Get(StateSkillTip)
    self.stateSkillT:Init(skilTip)
    
    self.curFloorLab = CG(UILabel,root,"curSLab",name)
    self.stateSInfo = ObjPool.Get(StateSInfo)
    self.stateSInfo:Init(stateS,self)

    self.stateMInfo = ObjPool.Get(StateModInfo)
    self.stateMInfo:Init(self.modelRoot,self)

    self.statePInfo = ObjPool.Get(StatePInfo)
    self.statePInfo:Init(stateP,self)
    
    self.missionPInfo = ObjPool.Get(MissionPanel)
    self.missionPInfo:Init(missionP,self.stateMInfo)

    
    self.prayMInfo = ObjPool.Get(UIPrayPanel)
    self.prayMInfo:Init(self.prayM)
    
    -- self.stateExpInfo = ObjPool.Get(StateExpInfo)
    -- self.stateExpInfo:Init(self.expP)
    -- self.stateEGbj = self.stateExpInfo.Gbj
    self:SetPrayBtn()
    self.stateSGbj = TFC(root,"StateInfo",name)
    self.statePGbj = self.statePInfo.Gbj

    USBC(root,"curName", name, self.ClickCurNameBtn, self)
    USBC(root,"pryBtn", name, self.ClickPryBtn, self)
    US(self.ruBtnG, self.ClickRobbyBtn, self)
    US(self.desBtn, self.OnClickStDBtn, self)
    -- US(self.fightBox,self.OnTotalProp,self) 
    US(self.spBtn,self.OnClickSpBtn,self)
    self:AddEvent()
    self.lastIndex = 0
    self.aniState = 0
    self.curShowIndex = 1
end

function My:OnClickSpBtn()
    self.roInfo:OpenByCurIndex(2)
end

function My:AddEvent()
    -- FightVal.eChgFv:Add(self.UpdateFight, self)
    self:SetEvent("Add")
end

function My:RemoveEvent()
    -- FightVal.eChgFv:Remove(self.UpdateFight, self)
    self:SetEvent("Remove")
end

function My:SetEvent(fn)
    RobberyMgr.eUpdateStateInfo[fn](RobberyMgr.eUpdateStateInfo, self.SeChange, self)
    OpenMgr.eOpenNow[fn](OpenMgr.eOpenNow, self.SetPrayBtn, self)
    RobberyMgr.eStateSpRed[fn](RobberyMgr.eStateSpRed, self.RefreshRed, self)
    self.missionPInfo.eMissionUpdate[fn](self.missionPInfo.eMissionUpdate, self.ShowDifEff, self)
    FamilyBossMgr.eWorldLv[fn](FamilyBossMgr.eWorldLv,self.RefreshCloseExp,self)
    PrayMgr.eChangeRes[fn](PrayMgr.eChangeRes,self.RefreshCloseExp,self)
    UserMgr.eLvEvent[fn](UserMgr.eLvEvent,self.RefreshCloseExp,self)
    PropMgr.eUpdate[fn](PropMgr.eUpdate,self.UpConsumeLab,self)
end

function My:Open()
    self:ShowDifPanel(1)
    self:LoadBgTex()
    self:LoadPropCell()
    self.stateSInfo:RefreshSShow()
    self:SetCurName()
    self.missionPInfo:Open()
    -- self:UpdateFight()
    self:UpConsumeLab()
    self.statePTAct:SetTotalP()
    -- self.Gbj.gameObject:SetActive(true)
    self:ShowDifEff()
    self:IsShowSpBtn()
    self:RefreshRed()
end

function My:RefreshRed()
    local tab = RobberyMgr.StateSpRedTab
    local red = false
    for k,v in pairs(tab) do
        if v == true then
            red = true
            break
        end
    end
    if self.spRed then
        self.spRed:SetActive(red)
    end
end

--闭关信息刷新
function My:RefreshCloseExp()
    -- local isOpen = PrayMgr:IsOpen()
    -- if isOpen == false then return end
    if self.stateExpInfo then
        self.stateExpInfo:RefreshData()
    end
end

function My:SetPrayBtn()
    local isOpen = PrayMgr:IsOpen()
    if isOpen == true then
        self.prayM.gameObject:SetActive(true)
        self.prayBtnG:SetActive(true)
        self.stateExpInfo = ObjPool.Get(StateExpInfo)
        self.stateExpInfo:Init(self.expP,self)
        self.stateEGbj = self.stateExpInfo.Gbj
    else
        self.prayM.gameObject:SetActive(false)
        self.prayBtnG:SetActive(false)
    end
end

function My:SeChange()
    self:SetCurName()
    self.statePTAct:SetTotalP()
    self.stateSInfo:RefreshSShow()
    self:IsShowSpBtn()
    local len = #self.statePInfo.items
    if len > 0 then
        self.statePInfo:RefreshItem()
    end
end

function My:ShowDifEff()
    self:IsIdealAni()
    self:RewardBox()
end

--是否是待机动画
--点击突破后的小窗
function My:IsIdealAni()
    self:NeedTime()
end

function My:RewardBox()
    local state = RobberyMgr.RobberyState
    local cfg = nil
    local cfg = RobberyMgr:GetNextCfg()
    if state == 1 then
        cfg = RobberyMgr:GetCurRewCfg()
    elseif state == 5 then
        cfg = RobberyMgr:GetNextCfg()
    end
    local stateId = cfg.id
    local rewardTab = RobberyMgr:GetCurSReward(stateId)
    local reId = rewardTab[1]
    local index = 0
    local strReId = tostring(reId)
    if SpiriteCfg[strReId] then
        index = 1
    else
        index = 2
    end
    self.stateMInfo:ShowReBox(index,reId)
end

--渡劫副本打完，未点击突破
function My:NeedTime()
    local state = RobberyMgr.RobberyState
    local recState = RobberyMgr.aniIndex
    local isSecSer = RobberyMgr.isSecond
    if recState == nil then
        recState = 0
    end
    local ac = false
    if state == 1 then --突破 （不打副本）
        self.aniState = 2
        self:AniState()
        ac = true
        self.roLab1.gameObject:SetActive(true)
        self.roLab.gameObject:SetActive(false)
        self.ruBtnEffect:SetActive(true)
    elseif state == 5 then --渡劫 （打副本）
        if recState == 0 or recState == 1 then
            self.aniState = 1
            self:AniState()
        end
        self.roLab1.gameObject:SetActive(false)
        self.roLab.gameObject:SetActive(true)
        self.ruBtnEffect:SetActive(true)
    elseif state == 0 then
        if isSecSer == true then
            self.aniState = 4
            self:AniState()
            RobberyMgr.isSecond = false
        end
        self.roLab1.gameObject:SetActive(false)
        self.roLab.gameObject:SetActive(true)
        self.ruBtnEffect:SetActive(false)
    end
end


--state
--1:所有任务奖励领取完
--2:渡劫副本打完还未点击突破
--3:点击突破后
--4:点击突破后的小窗
function My:AniState()
    --0:女   1：男
    local roleCate = User.MapData.Sex
    local isSecond = RobberyMgr.isSecond
    local roState = RobberyMgr.RobberyState
    local curCfg = RobberyMgr:GetCurCfg()
    if curCfg == nil then
        return
    end
    local curReCfg = RobberyMgr:GetCurRewCfg()
    local enterCopyId = curCfg.needCopyId
    if isSecond == false and roState == 1 then
        enterCopyId = curReCfg.needCopyId
    else
        enterCopyId = curCfg.needCopyId
    end
    if enterCopyId <= 0 then
        return
    end
    local state = self.aniState
    if state == 0 then
        iTrace.eError("GS","动画状态不正确，需要检查")
        return
    end
    local treeId= 0 --流程树id
    if roleCate == 0 then
        treeId = AmbitAniCfg[state].femaleTreeId
    else
        treeId = AmbitAniCfg[state].maleTreeId
    end
    treeId = tostring(treeId)
    self.curTreeid = treeId
    self:StartTree(treeId,state)
end

--开启流程树
function My:StartTree(three,index)
    if index == 3 then        
        self.ruBtnEffect:SetActive(false)
        FlowChartUtil.eStart:Add(self.TreeStart, self)
        FlowChartUtil.eEnd:Add(self.TreeEnd, self)
    else
        FlowChartUtil.eStart:Add(self.RecordTreeStart, self)
        FlowChartUtil.eEnd:Add(self.RecordTreeEnd, self)
    end
    FlowChartMgr.Start(three)
end

function My:TreeStart(name)
    local handId = self:GetHandEff()
    local gatherBallid = 22
    self.stateMInfo:ModelActive(true,gatherBallid)
    self.stateMInfo:ModelActive(true,handId)
    self.stateMInfo:AllBallEff(false)
    FlowChartUtil.eStart:Remove(self.TreeStart, self)
    UITool.SetLsnrSelf(self.ruBtnG, self.ReturnRobbyBtn, self)
end

function My:TreeEnd(name)
    local handId = self:GetHandEff()
    local gatherBallid = 22
    if self.stateMInfo then
        self.stateMInfo:ModelActive(false,gatherBallid)
        self.stateMInfo:ModelActive(false,handId)
    end
    if LuaTool.IsNull(self.ruBtnG) then
        return
    end
    UITool.SetLsnrSelf(self.ruBtnG, self.ClickRobbyBtn, self)
    FlowChartUtil.eEnd:Remove(self.TreeEnd, self)
    self:ClearTree()
    self:ShowRobberyTip()
end

function My:RecordTreeStart(name)
    FlowChartUtil.eStart:Remove(self.RecordTreeStart, self)
end

function My:RecordTreeEnd(name)
    self:ClearTree()
    FlowChartUtil.eStart:Remove(self.RecordTreeEnd, self)
end

function My:ReturnRobbyBtn()
    UITip.Error("动画播放中...")
end

--模型手的特效
function My:GetHandEff()
    local roleCate = User.MapData.Sex
    local index = 0
    if roleCate == 0 then --手的残影特效
        index = 4
    else
        index = 2
    end
    return index
end

--弹出UI
function My:ShowRobberyTip()
    local nextCfg = RobberyMgr:GetNextCfg()
	local RoleCate = User.MapData.Sex
	local skilTab = nextCfg.getSkill
	local skilBookTab = nextCfg.getBook
	local skilTabLen = #skilTab
	local skilBookLeb = #skilBookTab
	local isSkill = skilTabLen > 0
	local curTab = isSkill == true and skilTab or skilBookTab
	local skillId = RoleCate == curTab[1].k and curTab[1].v or curTab[2].v
    if isSkill then
        UIRobberyTip:OpenRobberyTip(0,true)
    else
        UIRobberyTip:OpenRobberyTip(1,true)
    end
end

function My:LoadBgTex()
    AssetMgr:Load("dujie.png",ObjHandler(self.LoadBgIcon,self))
end

function My:LoadBgIcon(icon)
    if self.bgName then
        return
    end
    self.bgTexture.mainTexture = icon
    self.bgName = self.bgTexture.mainTexture.name
end

--渡劫丹数据
function My:LoadPropCell()
    local itemid = tostring(117)
    local itemCfg = ItemData[itemid]
    local iconPath = itemCfg.icon
    AssetMgr:Load(iconPath,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(icon)
    if self.propName then
        return
    end
    self.propTexture.mainTexture = icon
    self.propName = self.propTexture.mainTexture.name
end

--刷新消耗当前道具数量
function My:UpConsumeLab()
    -- local smallState = RobberyMgr.StateInfoTab.smallState
    -- local bigState = RobberyMgr.StateInfoTab.bigState
    -- if smallState == nil or bigState == nil then
    --     return
    -- end
    local cur = RobberyMgr:GetCurCfg()
    if cur == nil then
        return
    end
    local need = cur.costNum
    self.consumeGbj:SetActive(need > 0)
    local itemid = 117
    local sb = ObjPool.Get(StrBuffer)
    itemid = tostring(itemid)
    local itemData = ItemData[itemid]
    local own = PropMgr.TypeIdByNum(itemid)
    if own < need then
        self.isCanRoProp = false
    elseif (own > 0 and own >= need) or need == 0 then
        self.isCanRoProp = true
    end
    local str = "渡劫丹消耗："
    local propC = (own < need and "[e83030]" or "[67cc67]")
    local desLabC = "[F39800FF]"
    sb:Apd(str):Apd(propC):Apd(own):Apd("[-]"):Apd("/"):Apd(need)
    self.praceLab.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:OnClickStDBtn(go)
    -- local desInfo = InvestDesCfg["1021"]
    -- local str = desInfo.des
    -- UIComTips:Show(str, Vector3(182,178,0),nil,nil,nil,nil,UIWidget.Pivot.TopRight)
    self:OnTotalProp()
end

--点击渡劫
function My:ClickRobbyBtn()
    -- self:EnterCopyScene()
    self:ClearTree()
    local isCanRo = self:IsCanRobbery()
    if isCanRo == true then
        self.missionPInfo:HideMissItem(self.stateMInfo)
        self.aniState = 3
        self:AniState()
        return
    end
    local missionTab = self.missionPInfo.MissionTab
    local len = #missionTab
    for i = 1,len do
        local info = missionTab[i]
        if info.status == 1 then
            UITip.Error("请完成任务")
            return
        elseif info.status == 2 then
            UITip.Error("请领取任务奖励")
            return
        end
    end

    if self.isCanRoProp == nil or self.isCanRoProp == false then
        local isExitGift = DiscountGiftMgr:IsExitGift(370)
        if not isExitGift then
            DiscountGiftMgr:SendRobberyGift()
        else
            UITip.Error("道具不足")
            self:ClickWayBtn()
        end
        return
    end

    local mgr = RobberyMgr
    local curState = mgr.curState
    local curCfg = mgr:GetCurCfg()
    local preCfg = mgr:GetPreCfg(curState)
    if curCfg == nil then
        return
    end
    self.enterCopyId = curCfg.needCopyId
    -- local isFirstPay = FirstPayMgr:IsPayState()
    -- if (isFirstPay == nil or isFirstPay == false) and curState == 1202 then
    --     self:ShowMessage()
    --     return
    -- end
    self:EnterCopyScene(curCfg.needCopyId)
end

function My:EnterCopyScene(Id)
    local mapId = RobberyMgr.RobberySceneId
    SceneMgr:ReqPreEnter(mapId,false,true)

    -- local copyId = Id
    -- if copyId == 0 then
    --     iTrace.eError("GS","渡劫副本id为零")
    --     return
    -- end
    -- copyId = tostring(copyId)
    -- local copyinfo = SceneTemp[copyId]
    -- copyId = copyinfo.id
    -- SceneMgr:ReqPreEnter(copyId,true,true)
end

--是否可以渡劫
function My:IsCanRobbery()
    local isRobbery = false
    --1，成功   2，失败
    local state = RobberyMgr.RobberyState
    if state == 1 then
        isRobbery = true
    end
    return isRobbery
end

function My:OnTotalProp()
    self.statePTAct:OnTotalProp()
end

function My:SetCurName()
    local curInfo = RobberyMgr:GetCurCfg()
    if curInfo == nil then
        return
    end
    -- self.curStateLab.text = curInfo.nameOnly
    -- self.curStateLab.text = "境界预览"
    local curName = curInfo.floorName
    local curSmall = curInfo.step.k
    local curMax = curInfo.step.v
    local str = string.format("%s (%s/%s)",curName,curSmall,curMax)
    self.curFloorLab.text = str
end

function My:UpdateFight()
    local lb = self.fightLab
    if lb then
        local fightNum = User.MapData:GetFightValue(FightType.ROLE_STATE)
		local fight = tonumber(fightNum)
		if not fight then fight = 0 end
		lb.text = "战力: " .. tostring(fight)
	end
end

function My:IsShowSpBtn()
    local isShow = RobberyMgr:IsShowSpBtn()
    self.spBtn.gameObject:SetActive(isShow)
end

--点击闭关修炼
function My:ClickPryBtn()
    local index = self.curShowIndex
    if index ~= 2 then
        index = 2
    elseif index == 2 then
        index = 1
    end
    self.curShowIndex = index
    self:ShowDifPanel(index)
end

--点击当前境界按钮
function My:ClickCurNameBtn()
    local index = self.curShowIndex
    if index ~= 3 then
        index = 3
    elseif index == 3 then
        index = 1
    end
    self.curShowIndex = index
    self:ShowDifPanel(index)
end


--显示不同面板
--index：1：境界    2：闭关收益    3：境界预览   
function My:ShowDifPanel(index)
    local stateS = self.stateSGbj
    local stateE = self.stateEGbj
    local stateP = self.statePGbj
    self:ShowDifData(index)
    stateS.gameObject:SetActive(index == 1)
    if stateE then
        stateE.gameObject:SetActive(index == 2)
    end
    stateP.gameObject:SetActive(index == 3)
    self:ShowDifLab(index)
end

function My:ShowDifData(index)
    local len = #self.statePInfo.items
    -- local count = #self.stateExpInfo.spItems
    if index == 3 then 
        if len == 0 then 
            self.statePInfo:InitState()
        else
            self.statePInfo:SetCurCenter()
        end
    elseif index == 2 then
        self.stateExpInfo:RefreshData()
    end
end

function My:ShowDifLab(index)
    local lab1 = self.pryLab --闭关
    local lab2 = self.curStateLab --境界预览
    local sp1 = self.prySp
    local sp2 = self.curStateSp
    local labTab = {"闭关收益","境界预览","返回境界"}
    local spTab = {"dj_n12","dj_n13","dj_n14"}
    if index == 1 then
        lab1.text = labTab[1]
        lab2.text = labTab[2]
        sp1.normalSprite = spTab[1]
        sp2.normalSprite = spTab[2]
    elseif index == 2 then
        lab1.text = labTab[3]
        lab2.text = labTab[2]
        sp1.normalSprite = spTab[3]
        sp2.normalSprite = spTab[2]
    elseif index == 3 then
        lab1.text = labTab[1]
        lab2.text = labTab[3]
        sp1.normalSprite = spTab[1]
        sp2.normalSprite = spTab[3]
    end
end


--点击获取途径
function My:ClickWayBtn()
    -- local UserLv = User.MapData.Level
    -- local NeedLv = GlobalTemp["136"].Value3

    -- if UserLv >= NeedLv then
    --     UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb1 ,self)
    -- else
    --     local str = string.format("心魔副本%s级开启",NeedLv)
    --     UITip.Error(str)
    -- end
    -- local getWayCfg = ItemData["117"].getwayList
    -- if getWayCfg == nil then
    --     iTrace.eError("GS","检查道具 渡劫丹  id:117  获取途径配置")
    --     return
    -- end
    -- local pos = Vector3.New(30,-50,0)
    -- GetWayFunc:GetWayKVList(getWayCfg,pos)
    GetWayFunc.ItemGetWay(117)
end

function My:OpenGetWayCb1(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(30,-50,0))
	ui:CreateCell("心魔副本", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    if name == "心魔副本" then
        MissionMgr:ExecuteRebberyMiss()
        -- self:ShowMessageBox()
	end
end

function My:ShowMessage()
    MsgBox.ShowYesNo("当前渡劫存在风险\n推荐提升战力后进行挑战",self.EnterCopyCb,self,"立即进入",self.FirstCb,self,"提升战力")
end

--打开首充界面
function My:FirstCb()
    UIFirstPay:OpenFirsyPay()
end

--进入副本
function My:EnterCopyCb()
    local id = self.enterCopyId
    if id == nil or id == 0 then
        return
    end
    self:EnterCopyScene(id)
end

function My:ShowMessageBox()
    MsgBox.ShowYesNo("是否进入心魔副本进行挑战",self.ContinueCb,self)
end

function My:ContinueCb()
	MissionMgr:ExecuteRebberyMiss()
end

function My:UnLoadBgTex()
    if self.bgName == nil then
        return
    end
    AssetTool.UnloadTex(self.bgName)
    self.bgName = nil
end

function My:UnLoadPropTex()
    if self.propName == nil then
        return
    end
    AssetTool.UnloadTex(self.propName)
    self.propName = nil
end

function My:CloseC()
    self.IsAutoClick = nil
    -- self.Gbj.gameObject:SetActive(false)
end

function My:ClearTree()
    if self.curTreeid then
        FlowChartMgr.Remove(self.curTreeid)
        self.curTreeid = nil
    end
end

function My:Dispose()
    self:RemoveEvent()
    self:ClearTree()
    self.lastIndex = 0
    self.getWayIndex = 0
    self.aniState = 0
    self.curShowIndex = 1
    self.isCanRoProp = false
    self.IsAutoClick = nil
    self.enterCopyId = 0
    self:UnLoadBgTex()
    self:UnLoadPropTex()
    ObjPool.Add(self.statePTAct)
    ObjPool.Add(self.stateSInfo)
    ObjPool.Add(self.missionPInfo)
    ObjPool.Add(self.statePInfo)
    ObjPool.Add(self.stateMInfo)
    ObjPool.Add(self.stateSkillT)
    ObjPool.Add(self.prayMInfo)
    if self.stateExpInfo then
        ObjPool.Add(self.stateExpInfo)
        self.stateExpInfo = nil
    end
    self.stateSInfo = nil
    self.statePInfo = nil
    self.missionPInfo = nil
    self.stateMInfo = nil
    self.stateSkillT = nil
    self.prayMInfo = nil

    self.stateSGbj = nil
    self.statePGbj = nil
    self.stateEGbj = nil
    self:CloseC()
    self.roInfo = nil
    -- TableTool.ClearUserData(self)
end