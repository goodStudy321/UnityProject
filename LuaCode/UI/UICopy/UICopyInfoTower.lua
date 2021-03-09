UICopyInfoTower = UICopyInfoBase:New{Name = "UICopyInfoTower"}

local M = UICopyInfoTower
local aMgr = Loong.Game.AssetMgr

function M:InitSelf()
    local global = GlobalTemp["48"]
    local t = global.Value1
    self.GID1 = t[1].id
    self.GID2 = t[2].id
    self.GID3 = t[3].id
    self.cost = global.Value2[2]
    self.SID1 = 10001
    self.SID2 = 10002
    self.selectType = 0   --点击的守卫类型
    self.fristCD = 0  --技能1cd
    self.secondCD = 0    --技能2cd 
    self.itemList = {}  --奖励列表 
    self.fxList = {}
    self:InitUserData()   
    self:SetEvent(EventMgr.Add)
end

function M:SetLsnrSelf(key)
    CopyMgr.eUpdateImmortalDrop[key](CopyMgr.eUpdateImmortalDrop, self.UpdateImmortalDrop, self)
    CopyMgr.eUpdateImmortalRemainMonster[key](CopyMgr.eUpdateImmortalRemainMonster, self.UpdateImmortalRemainMonster, self)
    CopyMgr.eUpdateImmortalRunMonster[key](CopyMgr.eUpdateImmortalRunMonster, self.UpdateImmortalRunMonster, self)
    CopyMgr.eUpdateImmortalUseSkill[key](CopyMgr.eUpdateImmortalUseSkill, self.UpdateImmortalUseSkill, self)
    CopyMgr.eUpdateImmortalInfo[key](CopyMgr.eUpdateImmortalInfo, self.UpdateImmortalInfo, self)
    CopyMgr.eImmortalStart[key](CopyMgr.eImmortalStart, self.ImmortalStart, self) 
    CopyMgr.eUpdateGuardNum[key](CopyMgr.eUpdateGuardNum, self.UpdateGuard, self) 
    CopyMgr.eUpdateGuardFx[key](CopyMgr.eUpdateGuardFx, self.UpdateGuardFx, self) 
end

function M:SetEvent(e)
    e("OnChangeLv",  EventHandler(self.UpdateRewardList, self))
end

function M:ImmortalStart()
    self.btnList:SetActive(false)
    self.arrows:SetActive(false)
    self:HideFx()
end

function M:HideFx()
    local list = self.fxList
    local len = #list
    for i=1,len do
        list[i].dizuo:SetActive(false)
        list[i].fangwei:SetActive(false)
    end
end

function M:InitUserData()
    local G = ComTool.Get
    local FG = TransTool.FindChild
    local SC = UITool.SetLsnrClick
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    
    local trans = self.left
 
    self.curProgress = G(UILabel, trans, "CurProgress")
    self.remainCount = G(UILabel, trans, "RemainCount")
    self.escapeCount = G(UILabel, trans, "EscapeCount")
    self.curScore = G(UILabel, trans, "CurScore")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")

    local other = F(self.root, "Other")
    local root = F(other, "BtnList")
    self.highlight1 = FG(root, "Btn1/Highlight")
    self.highlight2 = FG(root, "Btn2/Highlight")
    self.highlight3 = FG(root, "Btn3/Highlight")
    self.btnName1 = G(UILabel, root, "Btn1/Name")
    self.btnName2 = G(UILabel, root, "Btn2/Name")
    self.btnName3 = G(UILabel, root, "Btn3/Name")
    SC(root, "Btn1", "", self.OnBtn1, self)
    SC(root, "Btn2", "", self.OnBtn2, self)
    SC(root, "Btn3", "", self.OnBtn3, self)
    SC(root, "BtnSet", "", self.OnSet, self)
    SC(root, "BtnStart", "", self.OnStart, self)
    self.btnList = root.gameObject
    self.fxStart = FG(root, "BtnStart/FX_tishi")

    self.leftTop = FG(other, "LeftTop")  
    local tra = self.leftTop.transform
    SC(tra, "BtnReward", "", self.OnReward, self)
    SC(tra, "BtnSeek", "", self.OnSeek, self)
    SC(tra, "BtnBoss", "", self.OnBoss, self)
    self.rewardView = FG(tra, "RewardView")
    self.content = G(UILabel, tra, "RewardView/BG/ScrollView/Content")

    local skill01 = F(tra, "SkillList/BtnSkill01")
    self.fristSkillCD = G(UISprite, skill01, "CD")
    self.fristSkillCount = G(UILabel, skill01, "Count")
    S(skill01, self.OnSkill, self, nil, false)

    local skill02 = F(tra, "SkillList/BtnSkill02")
    self.secondSkillCD = G(UISprite, skill02, "CD")
    self.secondSkillCount = G(UILabel, skill02, "Count")
    S(skill02, self.OnSkill, self, nil, false)

    local parent = GameObject.Find("Area")
    if parent==nil then return end
    local tra = parent.transform
    for i=1,tra.childCount do
        local trans = tra:GetChild(i-1)
        S(trans, self.OnClickArea, self, nil, false)
        local dizuo = FG(trans, "fx_dizuo")
        local fangwei = G(DelayDestroy, trans, "fx_fangwei")
        fangwei.onDestroy = DelayDestroy.OnDestroy(self.OnDestroyFx, self)
        local t = {}
        t.dizuo = dizuo
        t.fangwei = fangwei.gameObject
        table.insert(self.fxList, t)
    end

    self.arrows = GameObject.Find("Arrows")
    self.callBoss = FG(other, "CallBoss")
    local trans = self.callBoss.transform
    self.cbToggle = G(UIToggle, trans, "bg/Toggle")
    self.cbMsg = G(UILabel, trans, "bg/msg")
    SC(trans, "bg/Toggle", "", self.OnToggle, self)
    SC(trans, "bg/BtnClose", "", self.OnCbClose, self)
    SC(trans, "bg/BtnNo", "", self.OnCbClose, self)
    SC(trans, "bg/BtnOk", "", self.OnCbOk, self)
end

function M:OnDestroyFx(go, unit)
    go:SetActive(false)
end

function M:OnToggle()
    CopyMgr:ReqCopyImmortalAutoSummonBoss(self.cbToggle.value)
end

function M:OnCbClose()
    self.callBoss:SetActive(false)
end

function M:OnCbOk()
    self.callBoss:SetActive(false)
    local info = CopyMgr.CopyInfo
    if not info.Cur or info.Cur==0 then
        UITip.Log("未开始刷怪，不能召唤Boss")
        return
    end

    if info.Cur ~= info.summonBossRound then
        CopyMgr:ReqCopyImmortalSummonBoss()
    else
        UITip.Log("您该轮已经召唤过Boss了")
    end
end

function M:OnClickArea(go)
    local info = CopyMgr.CopyInfo
    if not info or info.Cur>0 then return end
    local index = go.name
    local guardDic = info.guardDic
    local guard = guardDic[index]
    if guard and guard~=0 then
        CopyMgr:ReqCopyImmortalSetGuard(tonumber(index), 0)
    else
        if self.selectType~=0 then
            CopyMgr:ReqCopyImmortalSetGuard(tonumber(index), self.selectType)
        else
            UITip.Log("请选择要设置的守卫")
        end
    end
end


function M:Update()
    if self.fristCD > 0 then
        self.fristCD = self.fristCD - Time.unscaledDeltaTime
        if self.fristCD < 0 then
            self:LoadSkillFx("UI_Skill_ColdDown" , self.fristSkillCD.gameObject)
            self.fristCD = 0
        end
        self:UpdateSkillCD(self.SID1, self.fristSkillCD,  self.fristCD)
    end
    
    if self.secondCD > 0 then
        self.secondCD = self.secondCD - Time.unscaledDeltaTime
        if self.secondCD < 0 then
            self:LoadSkillFx("UI_Skill_ColdDown" , self.secondSkillCD.gameObject)
            self.secondCD = 0
        end
        self:UpdateSkillCD(self.SID2, self.secondSkillCD, self.secondCD)
    end
end


function M:UpdateSkillCD(id, skill, cd)
    if skill then
        local totalCD = XHSkillCfg[tostring(id)].cd
        skill.fillAmount = cd/totalCD
    end
end


function M:UpdateImmortalDrop(list)
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    local sb = self.sb
    sb:Dispose()
    local len = #list
    for i=1,len do
        local key = tostring(list[i].id)
        local data = ItemData[key]
        if data then
            local str = string.format("%s%s：%d[-]", UIMisc.LabColor(data.quality), data.name, list[i].val)
            sb:Apd(str)
            if i<len then
                sb:Line()
            end
        end
    end
    self.content.text = sb:ToStr()
end

function M:UpdateImmortalRemainMonster(remainCount)
    if self.remainCount then
        self.remainCount.text = string.format("[f4ddbd]剩余怪物：[f21919]%d[-][-]", remainCount)
    end
end

function M:UpdateImmortalRunMonster(runCount)
    if self.escapeCount then
        self.escapeCount.text = string.format("[f4ddbd]逃跑怪物：[f21919]%d[-][-]", runCount)
        self:UpdateRewardList()
    end
end


function M:UpdateRewardList()
    local info = CopyMgr.CopyInfo
    if not info then return end
    local runCount = info.runNum
    if not runCount then return end
    local grade = 0
    if not self.Temp then return end
    local sParam = self.Temp.sParam
    local sor = nil
    local str = "甲"
    if runCount <= sParam[1] then
        grade = 3
        str = "甲"
        sor = self.Temp.sor3
    elseif runCount <= sParam[2] then
        grade = 2
        str = "乙"
        sor = self.Temp.sor2
    else
        grade = 1
        str = "丙"
        sor = self.Temp.sor1
    end
    CopyMgr.CopyEndStar = grade

    local sCfg = XHCopyStarCfg
    local star = nil
    for i=1,#sCfg do
        if User.MapData.Level <= sCfg[i].level then
            if grade == 3 then
                star = sCfg[i].star3
            elseif grade == 2 then
                star = sCfg[i].star2
            else
                star = sCfg[i].star1
            end
            break
        end
    end
    sor = TableTool.CombList(sor, star)
    self.curScore.text = string.format("[f4ddbd]当前等级评价：[f39800]%s[-]级[-]", str)
    self:CreateItem(sor)
end

function M:CreateItem(data)
    local len = #data
    local list = self.itemList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then        
            list[i]:UpData(data[i].k, data[i].v)
            list[i].trans.gameObject:SetActive(true)
        elseif i <= count then
            list[i].trans.gameObject:SetActive(false)
        else
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.grid.transform, 0.7)
            item:UpData(data[i].k, data[i].v)
            table.insert(self.itemList, item)
        end
    end
    self.grid:Reposition()
end

function M:SetMenuStatus(value)
    self.leftTop:SetActive(value)
end

function M:UpdateImmortalUseSkill(id, cd, time)
    if id == self.SID1 then
        self.fristCD = cd
        self.fristSkillCount.text = time
    elseif id == self.SID2 then
        self.secondCD = cd
        self.secondSkillCount.text = time
    end
end

function M:UpdateImmortalInfo()
    local info = CopyMgr.CopyInfo
    
    if info.remainNum then
        self:UpdateImmortalRemainMonster(info.remainNum)
    end

    if info.runNum then
        self:UpdateImmortalRunMonster(info.runNum)
    end
    
    if info.skillDic then
        for k,v in pairs(info.skillDic) do
            self:UpdateImmortalUseSkill(v.id, v.cd, v.time)
        end
    end

    if info.guardNum then
        self:UpdateGuard(info.guardNum)
    end

    if info.guardDic then
        self:UpdateFx(info.guardDic)
    end 
end

function M:UpdateGuardFx(id, val)
    local list = self.fxList
    if id then
        if list[id] then
            local state = val==0
            list[id].dizuo:SetActive(state)
            list[id].fangwei:SetActive(not state)
        end
    else
        self:UpdateFx(CopyMgr.CopyInfo.guardDic)
    end
end


function M:UpdateFx(guardDic)
    if not guardDic then return end
    if CopyMgr.CopyInfo.Cur > 0 then return end
    local list = self.fxList
    for i=1, #list do
        local guard = guardDic[tostring(i)]
        local state = not guard or guard==0
        list[i].dizuo:SetActive(state)
        list[i].fangwei:SetActive(not state)
    end
end


function M:UpdateGuard(guardNum)
    local k1 = tostring(self.GID1)
    local k2 = tostring(self.GID2)
    local k3 = tostring(self.GID3)
    local t1 = guardNum[k1]
    local t2 = guardNum[k2]
    local t3 = guardNum[k3]
    self:UpdateNum(self.btnName1, MonsterTemp[k1].name, t1)
    self:UpdateNum(self.btnName2, MonsterTemp[k2].name, t2)
    self:UpdateNum(self.btnName3, MonsterTemp[k3].name, t3)
    self.fxStart:SetActive( t1+t2+t3 == 0 )
end

function M:UpdateNum(btnName, name, num)
    btnName.text = string.format("%sx%d", name, num)
end

function M:UpdateSelect()
    self.highlight1:SetActive(self.selectType == self.GID1)
    self.highlight2:SetActive(self.selectType == self.GID2)
    self.highlight3:SetActive(self.selectType == self.GID3)
end


function M:OnBtn1()
    self.selectType = self.GID1
    self:UpdateSelect()
end

function M:OnBtn2()
    self.selectType = self.GID2
    self:UpdateSelect()
end

function M:OnBtn3()
    self.selectType = self.GID3
    self:UpdateSelect()
end

function M:OnSet()
    CopyMgr:ReqCopyImmortalResetGuard()
end

function M:OnStart()
    CopyMgr:ReqCopyImmortalStart()
end

function M:OnReward()
    self.rewardView:SetActive(not self.rewardView.activeSelf)
end

function M:OnSeek()
    local info = CopyMgr.CopyInfo
    if not info then return end
    if not info.Cur or info.Cur == 0 then
        UITip.Log("未开始刷怪")
        return
    end

    local list = User:FindAllBoss()
    local count = list.Count
    if count == 0 then
        UITip.Log("神兽还在赶来的路上~~")
    elseif count == 1 then
        SelectRoleMgr.instance:StartNavPath(list[0], 1)
    elseif count == 2 then
        if not self.curBoss or self.curBoss ~= list[0] then
            SelectRoleMgr.instance:StartNavPath(list[0], 1)
            self.curBoss = list[0]       
        else
            SelectRoleMgr.instance:StartNavPath(list[1], 1)
            self.curBoss = list[1]
        end
    end
end

function M:OnBoss()
    self.cbToggle.value = CopyMgr.CopyInfo.isAuto or false
    self.cbMsg.text = string.format("[f4ddbd]是否在本回合花费[00ff00]%s[-]绑元(绑元不足消耗元宝)召唤Boss？[-]", GlobalTemp["48"].Value3)
    self.callBoss:SetActive(true)
end

function M:OnSkill(go)
    local info = CopyMgr.CopyInfo
    local id = go.name == "BtnSkill01" and self.SID1 or self.SID2
    if not info.Cur or info.Cur==0 then
        local str = id == self.SID1 and "守卫攻击加成技能" or "守卫眩晕怪物技能" 
        UITip.Log(string.format("%s,刷怪后方可使用", str))
        return
    end   
    local skill = info.skillDic[tostring(id)]
    if skill.time > 0 then
        if (id == self.SID1 and  self.fristCD > 0)
        or (id == self.SID2 and self.secondCD > 0)
        then
            UITip.Log("CD正在冷却中")
            return
        end
        self:LoadSkillFx("UI_Skill_Clik1" , go)
        CopyMgr:ReqCopyImmortalUseSkill(id)
    else
        UITip.Log("技能次数已用完！")
    end
end

function M:LoadSkillFx(name , go)
    local function LoadCb(effect)
        local trans = effect.transform
        trans:SetParent(go.transform)
        trans.localPosition = Vector3.zero
        trans.localScale = Vector3.one
    end
    aMgr.LoadPrefab(name, GbjHandler(LoadCb))
end


function M:InitData()  
    local info = CopyMgr.CopyInfo
    self:UpdateCur()
    self:UpdateImmortalInfo()
    local state = not info.Cur or info.Cur==0
    self.btnList:SetActive(state)
    self.arrows:SetActive(state)
end

function M:UpdateCur()
    local info = CopyMgr.CopyInfo
    self.curProgress.text = string.format("[f39800]当前进度:第[00ff00]（%d/%d）[-]轮[-]", info.Cur or 0, info.totalWave)
end


function M:DisposeSelf()
    self:SetEvent(EventMgr.Remove)
    self.GID1 = nil
    self.GID2 = nil
    self.GID3 = nil
    self.cost = nil
    self.SID1 = nil
    self.SID2 = nil
    self.selectType = nil   --点击的守卫类型
    self.fristCD = nil  --技能1cd
    self.secondCD = nil    --技能2cd  
    self.curBoss = nil
    TableTool.ClearListToPool(self.itemList)
    TableTool.ClearDic(self.fxList)
    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
end

return M