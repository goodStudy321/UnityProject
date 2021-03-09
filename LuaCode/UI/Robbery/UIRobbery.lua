require("UI/Base/UILoadBase")
require("UI/Robbery/StatePanel")
-- require("ui/Base/UIMoneyTreePanel")
require("UI/UIFiveNat/FiveCopy")
require("UI/Robbery/SpiritePanel")
require("UI/Robbery/SpiriteSkillTip")
require("UI/Robbery/SpiritG/SpiritGPanel")
require("UI/Robbery/Ares/UIAresPanel")
require("UI/Robbery/SpiritEquips/SpiriteEquips")
require("UI/Robbery/StateModelCfg")
require("UI/UIAlchemy/CommonAlchemy")
require("UI/UISecretArea/UISecretArea")

UIRobbery = UIBase:New{Name = "UIRobbery"}

local My = UIRobbery


My.OpenIndex = 1
My.FOneIndex = 0
My.FTwoIndex = 0
My.FThreeIndex = 0
My.IsSpirit = false --是否从主界面打开战灵
--index == 1 境界 2 战灵 3 灵饰 4 战神套装--5 灵器 11五行秘境 12 --秘境探索13 --炼丹炉14 --摇钱树
My.index = nil
My.isStateInit = true --判断境界初始化
My.isFiveInit = true --判断五行秘境初始化
My.isSecInit = true --判断秘境探索初始化
My.isAlcheInit = true --判断炼丹炉初始化
My.isMoneyInit = true --判断摇钱树初始化
My.isWarSpInit = true --判断战灵初始化
My.isEquipSpInit = true --判断灵器初始化
My.isDoSpInit = true --判断灵饰初始化
My.isWarGoldInit = true --判断战神套装初始化

function My:InitCustom()
    local root = self.root
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local UC = UITool.SetLsnrClick
    local US = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild

    local togCom = TF(root,"comBG/TogGrid",des)
    local childTog = TF(root,"spBG/TogChild",des)
    self.tog = togCom
    self.togChild = childTog
    self.togGrid = togCom:GetComponent("UIGrid")

    self.StateTog = CG(UIToggle,togCom,"StateTog",des)
    self.FiveTog = CG(UIToggle,togCom,"FiveTog",des)
    self.SecTog = CG(UIToggle,togCom,"SecTog",des)
    self.AlcheTog = CG(UIToggle,togCom,"AlchemyTog",des)
    self.MoneyTog = CG(UIToggle,togCom,"MoneyTog",des)

    self.WarSpiritTog = CG(UIToggle,childTog,"WarSpiritTog",des)
    self.SpiritEquipTog = CG(UIToggle,childTog,"SpiritEquipTog",des)
    self.SpdecTog = CG(UIToggle,childTog,"SpdecTog",des)
    self.AresTog = CG(UIToggle,childTog,"AresTog",des)

    self.comOtherBG = TF(root,"comBG",des)
    self.comSpBG = TF(root,"spBG",des)

    self.stateRedG = TFC(togCom,"StateTog/action",des)
    self.fiveRedG = TFC(togCom,"FiveTog/action",des)
    self.secRedG = TFC(togCom,"SecTog/action",des)
    self.alcheRedG = TFC(togCom,"AlchemyTog/action",des)
    self.moneyRedG = TFC(togCom,"MoneyTog/action",des)


    self.spiriteRedG = TFC(childTog,"WarSpiritTog/action",des)
    self.equipRedG = TFC(childTog,"SpiritEquipTog/action",des)
    self.spdecRedG = TFC(childTog,"SpdecTog/action",des)
    self.aresRedG = TFC(childTog,"AresTog/action",des)

    UC(togCom,"StateTog",name,self.StateC,self)
    UC(togCom,"FiveTog",name,self.FiveC,self)
    UC(togCom,"SecTog",name,self.SecC,self)
    UC(togCom,"AlchemyTog",name,self.AlcheC,self)
    UC(togCom,"MoneyTog",name,self.MoneyC,self)


    UC(childTog,"WarSpiritTog",name,self.SpiritC,self)
    UC(childTog,"SpiritEquipTog",name,self.SpiritEquipC,self)
    UC(childTog,"SpdecTog",name,self.SpdecC,self)
    UC(childTog,"AresTog",name,self.AresC,self)

    UITool.SetBtnClick(root,"comBG/CloseBtn", name, self.OnClickCloseBtn, self)
    UITool.SetBtnClick(root,"spBG/CloseBtn", name, self.OnClose, self)

    self.StateAct = ObjPool.Get(StatePanel)
    self.FiveAct = ObjPool.Get(FiveCopy)
    self.SecAct = ObjPool.Get(UISecretArea)
    self.AlcheAct = ObjPool.Get(CommonAlchemy)
    self.MoneyAct = ObjPool.Get(UIMoneyTreePanel)

    self.SpiriteAct = ObjPool.Get(SpiritePanel)
    self.SpiriteEquips = ObjPool.Get(SpiriteEquips)
    self.SpdecAct = ObjPool.Get(SpiritGPanel)
    self.skiTip = ObjPool.Get(SpiriteSkillTip)
    self.AresAct = ObjPool.Get(UIAresPanel)

    self.skiTip:Init(TF(root,"skiTip",des))

    self:AddEvent()
    self:UpdateSecRedG()
end


function My:OnClickCloseBtn()
    self:Close()
    JumpMgr.eOpenJump()
end

function My:OnClose()
    self:CloseTopUI()
    local index = self.OpenIndex
    local isSp = self.IsSpirit
    if isSp == true then
        if index == 4 then
            if self.AresAct:CanClose() then
                self.IsSpirit = false
                self:Close()
            else
                AresMgr.eOpenView(AresMgr.MainView)
            end   
        else
            self.IsSpirit = false
            self:Close()
        end
        return
    end
    local isInit = self.isWarGoldInit
    if isInit then
        self:OpenCurIndex(1)
        return
    end
    if self.AresAct:CanClose() then
        self:OpenCurIndex(1)
    else
        AresMgr.eOpenView(AresMgr.MainView)
    end
end

function My:CloseTopUI()
    local active = UIMgr.GetActive(UITop.Name)
    if active ~= -1 then
        UIMgr.Close(UITop.Name)
    end
end

function My:AddEvent(fn)
    RobberyMgr.eUpdateStRedState:Add(self.UpdateStateRed, self)
    RobberyMgr.eUpdateSpRedState:Add(self.UpdateSpiriteRed, self)
    RobberyMgr.eCloseRobberyUI:Add(self.CloseUI, self)
    RobberyMgr.eOpenSpUI:Add(self.OpenSpUI, self)
    self.SpdecAct.eRedFalg:Add(self.UpdateSpdecRed, self)
    AresMgr.eUpdateRedPoint:Add(self.UpdateAresRed, self)
    RobEquipsMgr.eRfrRed:Add(self.UpdSpirEqRed,self);
    AlchemyMgr.eUpdateRedPoint:Add(self.UpdateAlchemysRed, self)
    FiveElmtMgr.eRed:Add(self.FiveRedIpDate,self)
    SecretAreaMgr.ePlunderHistory:Add(self.UpdateSecRedG,self)
    SecretAreaMgr.eGood:Add(self.UpdateSecRedG,self)
    MoneyTreeMgr.eRed:Add(self.UpdateMRed, self)
    
end

function My:RemoveEvent()
    RobberyMgr.eUpdateStRedState:Remove(self.UpdateStateRed, self)
    RobberyMgr.eUpdateSpRedState:Remove(self.UpdateSpiriteRed, self)
    RobberyMgr.eCloseRobberyUI:Remove(self.CloseUI, self)
    RobberyMgr.eOpenSpUI:Remove(self.OpenSpUI, self)
    self.SpdecAct.eRedFalg:Remove(self.UpdateSpdecRed, self)
    AresMgr.eUpdateRedPoint:Remove(self.UpdateAresRed, self)
    RobEquipsMgr.eRfrRed:Remove(self.UpdSpirEqRed,self);
    AlchemyMgr.eUpdateRedPoint:Remove(self.UpdateAlchemysRed, self)
    FiveElmtMgr.eRed:Remove(self.FiveRedIpDate,self)
    SecretAreaMgr.ePlunderHistory:Remove(self.UpdateSecRedG,self)
    SecretAreaMgr.eGood:Remove(self.UpdateSecRedG,self)
    MoneyTreeMgr.eRed:Remove(self.UpdateMRed, self)
end

--获得战灵，打开战灵界面
function My:OpenSpUI()
    self:OpenByCurIndex(2)
end

function My:CloseUI()
    self:Close()
end

--境界页签红点
function My:UpdateStateRed(isShow)
    if RobberyMgr.isStateRed == true or RobberyMgr.isMissRed == true or RobberyMgr.isPrayRed == true then
        self.stateRedG:SetActive(true)
    elseif RobberyMgr.isStateRed == false and RobberyMgr.isMissRed == false and RobberyMgr.isPrayRed == false then
        self.stateRedG:SetActive(false)
    end
end

--战灵页签红点
function My:UpdateSpiriteRed(isShow)
    if RobberyMgr.isSpiriteRed == true then--or (RobberyMgr.spRedId ~= nil and RobberyMgr.spRedId > 0 ) then
        self.spiriteRedG:SetActive(true)
    elseif RobberyMgr.isSpiriteRed == false then
        self.spiriteRedG:SetActive(false)
    end
end

--灵饰页签红点
function My:UpdateSpdecRed(isShow)
    local redInfo = SpiritGMgr.SpRedInfo --j：战灵id  l:红点状态
    local flagRed = false
    for j,l in pairs(redInfo) do
        if l == true then
            flagRed = true
            break
        end
    end
    self.spdecRedG:SetActive(flagRed)
end

--战神套装页签红点
function My:UpdateAresRed()
    self.aresRedG:SetActive(AresMgr:GetTotalRedPointState())
end

--五行秘境红点
function My:FiveRedIpDate(  )
    if not FiveElmtMgr.IsOpen() then
        self.fiveRedG:SetActive(false)
        return
    end
    if FiveElmtMgr.Red or FiveElmtMgr.GoNextRed or FiveElmtMgr.illRed or FiveElmtMgr.onceRed  then
        self.fiveRedG:SetActive(true)
    else
        self.fiveRedG:SetActive(false)
    end
end

function My:UpdateSecRedG()
    local value = false
    local mgr = SecretAreaMgr
    if mgr.IsOpen() == true then
        if mgr.IsPlunderRed == true or mgr.IsGoodRed== true then
            value = true
        end
    end
    self.secRedG:SetActive(value)
end

function My:GetMRed()
	local cost = MoneyTreeMgr:GetCostForVip()
	if cost then
		self:UpdateMRed(cost.v == 0)
	end
end

function My:UpdateMRed(value)
    local status = false
    local id = 709
    local isOpen = OpenMgr:IsOpen(id)
    if isOpen == true then
        status = value
    end
    self.moneyRedG:SetActive(status)
end

--凡品炼丹红点
function My:UpdateAlchemysRed()
    self.alcheRedG:SetActive(AlchemyMgr:GetCommonRedPointStatus())
end

--灵器页签红点
function My:UpdSpirEqRed()
    local red = RobEquipsMgr.SpirHasRed();
    self.equipRedG:SetActive(red);
end

function My:OnClickDesBtn(go)
    if go then
        go.gameObject:SetActive(false)
    end
end


function My:Update()
    if self.StateAct.Update then self.StateAct:UpdateGbj() end
    if self.SpiriteAct then
        if self.SpiriteAct.Update then self.SpiriteAct:UpdateGbj() end
    end
    if self.MoneyAct then
        if self.MoneyAct.Update then self.MoneyAct:UpdateGbj() end
    end
end

--邮件链接入口
function My:OpenTabByIdx(t1, t2, t3, t4)
    self.OpenIndex = t1
    self.FOneIndex = t2
    self.FTwoIndex = t3
    self.FThreeIndex = t4
    self:OpenCb()
end

--index == 1 境界

--index == 2 战灵
--index == 3 灵饰
--index == 4 战神套装
--index == 5 灵器

--index == 11 --五行秘境
--index == 12 --秘境探索
--index == 13 --炼丹炉
--index == 14 --摇钱树

--isSpirit:true  战灵相关
function My:OpenRobbery(index,dex1,dex2,dex3)
    UIRobbery.OpenIndex = index
    UIRobbery.FOneIndex = dex1 or 1
    UIRobbery.FTwoIndex = dex2 or 1
    UIRobbery.FThreeIndex = dex3 or 1
    local isOpen = true
    UIRobbery.IsSpirit = isSpirit
    if index > 1 and index < 10 then --判断战灵是否开启
        UIRobbery.IsSpirit = true
        local isSpOpen = RobberyMgr:IsShowSpBtn()
        if isOpen == false then
            local str = "系统未开启"
            UITip.Log(str)
            return
        end
    elseif index == 1 or index > 10 then --判断其他是否开启
        isOpen = UIRobbery.IsOpen()
    end
    if isOpen == false then
        return
    end
    local active = UIMgr.GetActive(UIRobbery.Name)
    local tipAc = UIMgr.GetActive(UIGetWay.Name)
    if tipAc ~= -1 then
        UIGetWay:Close()
    end
    if active ~= -1 then
        UIRobbery:OpenTab()
    else
        -- UIMgr.Open(UIRobbery.Name)
        UIMgr.Open(self.Name, self.OpenCb,self)
    end
end


function My:OpenCb()
    self:OpenTab()
    self:UpdateSpRed()
    self:UpdateStateRed()
    self:UpdateSpiriteRed()
    self:UpdateSpdecRed()
    self:UpdateAresRed()
    self:UpdSpirEqRed();
    self:UpdateAlchemysRed()
    self:FiveRedIpDate(  )
    self:UpdateSecRedG()
    self:GetMRed()
end

--index:页签id
--isOpen:true 开启    false ：未开启
--openLv:  开启等级
function My.IsOpen()
    local index = UIRobbery.OpenIndex
    local isOpen = true
    local str = ""
    if index == 11 then
        isOpen=FiveElmtMgr.IsOpen()
        local openLv = FiveElmtMgr.OpenLv()
        str = string.format("%s级开启，角色等级尚未达到",openLv)
    elseif index == 12 then
        local data,openLv =nil,nil
        isOpen,data,openLv = SecretAreaMgr.IsOpen
        if isOpen==false then UITip.Log(string.format("%s级开启，角色等级尚未达到",openLv))end
    elseif index == 13 then
        isOpen = AlchemyMgr.IsOpenCommonAlchemy
        str = string.format("炼丹炉未开启")
    elseif index == 14 then
        local id = 709
        isOpen = OpenMgr:IsOpen(id)
        local openLv = SystemOpenTemp["709"].trigParam
        str = string.format("%s级开启，角色等级尚未达到",openLv)
    end
    if isOpen == nil or isOpen == false then
        if index~=12 then UITip.Log(str)end
    else
        isOpen = true
    end
    return isOpen
end

function My:OpenTab()
    local openIndex = self.OpenIndex
    if openIndex > 1 and openIndex < 10 then
        self.IsSpirit = true
        self:OpenByCurIndex(openIndex)
        return
    end
    self:OpenCurIndex()
end

--打开其他相关
function My:OpenCurIndex()
    local openIndex = self.OpenIndex
    self:ShowChildTog(false)
    if openIndex == 1 then
        self:StateC()
    elseif openIndex == 11 then
        self:FiveC()
    elseif openIndex == 12 then
        self:SecC()
    elseif openIndex == 13 then
        self:AlcheC()
    elseif openIndex == 14 then
        self:MoneyC()
    end
end

--打开战灵相关
function My:OpenByCurIndex(openIndex)
    UIMgr.Open(UITop.Name)
    self:ShowChildTog(true)
    if openIndex == 2 then
        self:SpiritC()
    elseif openIndex == 3 then
        self:SpdecC()
    elseif openIndex == 4 then
        self:AresC()
    elseif openIndex == 5 then
        self:SpiritEquipC()
    end
end

--显示战灵相关页签
function My:ShowChildTog(isShow)
    if not LuaTool.IsNull(self.comOtherBG) then
        self.comOtherBG.gameObject:SetActive(not isShow)
    end
    if not LuaTool.IsNull(self.comSpBG) then
        self.comSpBG.gameObject:SetActive(isShow)
    end
end

--境界
function My:StateC()
    if self:IsCurTab(1) == true then
        return
    end
    My.index = 1
    local act = self.StateAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.StateTog
    self.StateTog.value = true
    if self.isStateInit then
        self:LoadPre()
        self.isStateInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--五行秘境
function My:FiveC()
    if not FiveElmtMgr.IsOpen() then
        local openLv = FiveElmtMgr.OpenLv()
        local  str = string.format("%s级开启，角色等级尚未达到",openLv)
        UITip.Log(str)
        self.curTog.value = true
        self.FiveTog.value = false
        return
    end
    if self:IsCurTab(11) == true then
        return
    end
    My.index = 11
    local act = self.FiveAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.FiveTog
    self.FiveTog.value = true
    if self.isFiveInit then
        self:LoadPre()
        self.isFiveInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--秘境探索
function My:SecC()
    local isOpen,data,openLv = SecretAreaMgr.IsOpen()
    if isOpen==false then
        if isOpen==false then UITip.Log(string.format("%s级开启，角色等级尚未达到",openLv))end
        self.curTog.value = true
        self.SecTog.value = false
        return
    end
    if self:IsCurTab(12) == true then
        return
    end
    My.index = 12
    local act = self.SecAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.SecTog
    self.SecTog.value = true
    if self.isSecInit then
        self:LoadPre()
        self.isSecInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--炼丹炉
function My:AlcheC()
    if not AlchemyMgr.IsOpenCommonAlchemy then
        UITip.Log(string.format("%s级开启，角色等级尚未达到", SystemOpenTemp["708"].trigParam))
        self.curTog.value = true
        self.AlcheTog.value = false
        return
    end
    if self:IsCurTab(13) == true then
        return
    end
    My.index = 13
    local act = self.AlcheAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.AlcheTog
    self.AlcheTog.value = true
    if self.isAlcheInit then
        self:LoadPre()
        self.isAlcheInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--摇钱树
function My:MoneyC()
    local id = 709
    local isOpen = OpenMgr:IsOpen(id)
    if isOpen == false then
        local openLv = SystemOpenTemp["709"].trigParam
        local str = string.format("%s级开启，角色等级尚未达到",openLv)
        UITip.Log(str)
        self.curTog.value = true
        self.MoneyTog.value = false
        return
    end

    if self:IsCurTab(14) == true then
        return
    end
    My.index = 14
    local act = self.MoneyAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.MoneyTog
    self.MoneyTog.value = true
    if self.isMoneyInit then
        self:LoadPre()
        self.isMoneyInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--加载预制体
function My:LoadPre()
    local uiName = self.CurAct.Name
    AssetMgr:Load(uiName, ".prefab", ObjHandler(self.LoadSet,self))
    -- Loong.Game.AssetMgr.LoadPrefab(uiName, GbjHandler(self.LoadSet,self))
end

--加载完成后设置面板游戏对象
function My:LoadSet(obj)
	if LuaTool.IsNull(obj) then
		iTrace.eError("GS", "load ui prefab is null")
	else
        local go = Instantiate(obj)
        ShaderTool.eResetGo(go)
		self:SetName(go)
	end
end

function My:SetName(go)
    local name = string.gsub(go.name, "%(Clone%)", "")
    go.name = name
    local trans = go.transform
    trans.parent = self.root
    trans.localScale = Vector3.one
    trans.localPosition = Vector3.zero
    -- go:SetActive(true)
    self.CurAct.GbjRoot = go.transform
    self.CurAct.RobInfo = self
    self.CurAct:InitGbj()
    self.CurAct:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
    self:ResetOpenIndex()
end

--战灵
function My:SpiritC()
    if self:IsCurTab(2) == true then
        return
    end
    My.index = 2
    local act = self.SpiriteAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.WarSpiritTog
    self.WarSpiritTog.value = true
    if self.isWarSpInit then
        self:LoadPre()
        self.isWarSpInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
    if RobberyMgr.spRedId ~= nil then
        local spId = tostring(RobberyMgr.spRedId)
        local modObj = act.items[spId].root
        act:OnClickItem(modObj)
        RobberyMgr.spRedId = nil
    end
end

--点击灵器
function My:SpiritEquipC()
    if self:IsCurTab(5) == true then
        return
    end
    My.index = 5
    local act = self.SpiriteEquips
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.SpiritEquipTog
    self.SpiritEquipTog.value = true
    if self.isEquipSpInit then
        self:LoadPre()
        self.isEquipSpInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--灵饰
function My:SpdecC()
    local limitLv = SystemOpenTemp["67"].trigParam
    local userLv = User.MapData.Level
    if userLv < limitLv then
        local lvStr = UserMgr:chageLv(limitLv)
        local tipStr = string.format("%s级开启，角色等级尚未达到",lvStr)
        UITip.Log(tipStr)
        self.curTog.value = true
        self.SpdecTog.value = false
        return
    end
    if self:IsCurTab(3) == true then
        return
    end
    My.index = 3
    local act = self.SpdecAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.SpdecTog
    self.SpdecTog.value = true
    if self.isDoSpInit then
        self:LoadPre()
        self.isDoSpInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

--战神套装
function My:AresC()
    local limitLv = SystemOpenTemp["62"].trigParam
    local userLv = User.MapData.Level
    if userLv < limitLv then
        local lvStr = UserMgr:chageLv(limitLv)
        local tipStr = string.format("%s级开启，角色等级尚未达到",lvStr)
        UITip.Log(tipStr)
        self.curTog.value = true
        self.AresTog.value = false
        return
    end
    if self:IsCurTab(4) == true then
        return
    end
    My.index = 4
    local act = self.AresAct
    self.CloseCurAct()
    self.CurAct = act
    self.curTog = self.AresTog
    self.AresTog.value = true
    if self.isWarGoldInit then
        self:LoadPre()
        self.isWarGoldInit = false
        return
    end
    act:OpenGbj(self.FOneIndex,self.FTwoIndex,self.FThreeIndex)
end

function My:IsCurTab(index)
    if self.index == index then
        return true
    end
    return false
end

function My.CloseCurAct()
    local act = My.CurAct
    if act == nil then
        return
    end
    My.CurAct:CloseGbj()
end

--点击 境界 界面战灵按钮
function My:OnClickSpBtn()
    self:OpenByCurIndex(2)
end

function My:UpdateSpRed()
    -- RobberyMgr.spRedId = 10301
    if RobberyMgr.spRedId ~= nil and RobberyMgr.spRedId > 0 then
        local spid = tostring(RobberyMgr.spRedId)
        local spcfg = SpiriteCfg[spid]
        self.getSpid = spcfg.uiMod
    end
end

function My:CloseCustom()
    local name = FlowChartMgr.CurName
    if StrTool.IsNullOrEmpty(name) == false then
        local id = tonumber(name)
        for i,v in ipairs(AmbitAniCfg) do
            if v.maleTreeId == id or v.femaleTreeId == id then
                FlowChartMgr.Current = nil
                return
            end
        end
    else
        FlowChartMgr.Current = nil
    end
end

function My:ResetOpenIndex()
    self.FOneIndex = 0
    self.FTwoIndex = 0
    self.FThreeIndex = 0
end

function My:DisposeCustom()
    self:RemoveEvent()
    self.index = nil
    My.CurAct = nil
    self.curTog = nil

    ObjPool.Add(self.skiTip)
    self.skiTip = nil

    if self.isStateInit == false then
        ObjPool.Add(self.StateAct)
        self.StateAct:DisposeGbj()
        self.StateAct = nil
    end

    if self.isMoneyInit == false then
        ObjPool.Add(self.MoneyAct)
        self.MoneyAct:DisposeGbj()
        self.MoneyAct = nil
    end

    if self.isFiveInit == false then
        ObjPool.Add(self.FiveAct)
        self.FiveAct:DisposeGbj()
        self.FiveAct = nil
    end

    if self.isWarSpInit == false then
        ObjPool.Add(self.SpiriteAct)
        self.SpiriteAct:DisposeGbj()
        self.SpiriteAct = nil
    end

    if self.isEquipSpInit == false then
        ObjPool.Add(self.SpiriteEquips)
        self.SpiriteEquips:DisposeGbj()
        self.SpiriteEquips = nil;
    end

    if self.isDoSpInit == false then
        ObjPool.Add(self.SpdecAct)
        self.SpdecAct:DisposeGbj()
        self.SpdecAct = nil
    end

    if self.isWarGoldInit == false then
        ObjPool.Add(self.AresAct)
        self.AresAct:DisposeGbj()
        self.AresAct = nil
    end

    if self.isAlcheInit == false then
        ObjPool.Add(self.AlcheAct)
        self.AlcheAct:DisposeGbj()
        self.AlcheAct = nil
    end

    if self.isSecInit == false then
        ObjPool.Add(self.SecAct)
        self.SecAct:DisposeGbj()
        self.SecAct = nil
    end

    self.isStateInit = true --判断境界初始化
    self.isFiveInit = true --判断五行秘境初始化
    self.isSecInit = true --判断秘境探索初始化
    self.isAlcheInit = true --判断炼丹炉初始化
    self.isMoneyInit = true --判断摇钱树初始化 

    self.isWarSpInit = true --判断战灵初始化
    self.isEquipSpInit = true --判断灵器初始化
    self.isDoSpInit = true --判断灵饰初始化
    self.isWarGoldInit = true --判断战神套装初始化

    self.OpenIndex = 1
    self.FOneIndex = 0
    self.FTwoIndex = 0
    self.FThreeIndex = 0
    self.IsSpirit = false
    self.index = nil
end

return My