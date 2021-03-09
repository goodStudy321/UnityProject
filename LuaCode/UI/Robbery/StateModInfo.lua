StateModInfo = Super:New{Name = "StateModInfo"}
local My = StateModInfo
local Renderer = UnityEngine.Renderer

function My:Init(go,statePanelInfo)
    local root = go.transform
    self.Gbj = root
    self.statePanelInfo = statePanelInfo
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local USBC = UITool.SetBtnClick
    local UC = UITool.SetLsnrClick
    self.ballLineTab = {}
    self.ballBurstTab = {}
    self.ballTab = {}
    self.getCfgByName = {}
    self:GetCfgByName()

    self.modelTab = {}
    self.recordIndex = 1

    self.ModelNameTab = {"P_Male07_UI_Dujie","FX_UI_Dujie_hand","P_Female04_UI_DuJie","FX_UI_Dujie_hand_lv"}

    self.modCam = TF(root,"modCam")
    --0:女   1：男
    local modPath = ""
    local roleCate = User.MapData.Sex
    local index = 0 --角色模型显示
    local showId = 0 --模型显示特效
    local hideId = 0 --模型隐藏特效
    if roleCate == 1 then
        index = 1
        showId = 17
        hideId = 16
    else
        index = 3
        showId = 19
        hideId = 18
    end
    self.modelId = index
    self.showId = showId
    self.hideId = hideId
    self:ModelActive(true,index)

    local handId = self:GetHandEff()
    self:ModelActive(true,handId)

    -- self.stateMInfo:ModelActive(false,handId)

    -- --显示奖励的小球
    -- self:ModelActive(true,5)
    
    self.autoTimer = ObjPool.Get(iTimer)
    self.autoTimer.complete:Add(self.AutoExe,self)
end

--奖励小球特效
function My:RewardBallEff()
    local CG = ComTool.Get
    local TF = TransTool.Find
    local reBallGbj = self.modelTab[5]
    if reBallGbj then
        local reTrans = reBallGbj.transform
        local path = "icons/1"
        self.rewardTexture = CG(Renderer,reTrans, path)
        local boxPath = "btns/1"
        local box = TF(reTrans,boxPath)
        UITool.SetLsnrSelf(box, self.OnReBoxClick, self)
        self:ShowReBoxTex()
    end
end

--点击奖励box
function My:OnReBoxClick()
    local id = self.reBoxId
    local statePanelInfo = self.statePanelInfo
    local tipInfo = statePanelInfo.stateSkillT
    if id == nil then
        iTrace.eError("GS","渡劫点击奖励id为空")
        return
    end
    local strId = tostring(id)
    local spIndex = 0
    if SpiriteCfg[strId] then
        self.spIdIndex = id
        self:ClickSpReward()
    else
        local data = ItemData[strId] ~= nil and ItemData[strId] or SkillLvTemp[strId]
        tipInfo:Show(data,1)
    end
end

function My:ShowReBoxTex()
    local reId = self.reBoxId
    self.rewardTexture.gameObject:SetActive(true)
    local reId = tostring(reId)
    local spCfg = SpiriteCfg[reId]
    -- local skillCfg = SkillLvTemp[reId]
    local iconPath = nil
    if spCfg then
        iconPath = spCfg.mIcon
    -- elseif skillCfg then
    --     iconPath = spCfg.icon
    end
    if iconPath == nil then
        self.rewardTexture.gameObject:SetActive(false)
        return
    end
    self:ReBallTex(iconPath)
end

--显示战灵(贴图)或技能书(模型 id = 6)或天赋书(模型  id = 7)  奖励
--index 1:战灵    2 技能书 / 天赋书
function My:ShowReBox(index,id)
    self.reBoxId = id
    local id = tostring(id)
    local medTab = self.modelTab
    local cfg = nil
    local roMState = RobberyMgr.RobberyState
    if roMState == 1 or roMState == 5 then
        self:ModelActive(false,6)
        self:ModelActive(false,7)
        return
    end
    if index == 1 then
        if self.rewardTexture == nil then
            return
        end
        cfg = SpiriteCfg[id]
        self:ShowReBoxTex()
        if medTab[7] ~= nil then
            medTab[7]:SetActive(false)
        elseif medTab[6] ~= nil then
            medTab[6]:SetActive(false)
        end
    elseif index == 2 then
        if self.rewardTexture then
            self.rewardTexture.gameObject:SetActive(false)
        end
        cfg = ItemData[id]
        if cfg == nil then --奖励为技能
            if medTab[7] ~= nil then
                medTab[7]:SetActive(false)
            end
            self:ModelActive(true,6)
            return
        end
        if cfg.type == 6 then --技能书
            if medTab[7] ~= nil then
                medTab[7]:SetActive(false)
            end
            self:ModelActive(true,6)
        else
            if medTab[6] ~= nil then
                medTab[6]:SetActive(false)
            end
            self:ModelActive(true,7)
        end
    end
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

--获取模型状态
function My:GetModState(id)
    local tab = self.modelTab
    local state = false
    if tab[id] then
        state = tab[id].activeSelf
    end
    return state
end

--显示或隐藏技能或技能书模型
function My:ShowDif(state)
    local tab = self.modelTab
    if tab[6] then
        self:ModelActive(state,6)
    elseif tab[7] then
        self:ModelActive(state,7)
    end
end

--at:激活状态， id:配置id
function My:ModelActive(at,id)
    local cfg = StateModelCfg[id]
    if cfg == nil then
        iTrace.eError("GS","渡劫模型配置为空,id：" .. id)
        return
    end
    local modTab = self.modelTab
    local modeId = cfg.id
    local modName = cfg.modelName
    if at == false and modTab[modeId] == nil then
        return
    end
    if modTab[modeId] == nil and at == true then
        self:LoadMod(modName)
    elseif modTab[modeId] == nil then
        self:LoadMod(modName)
    else
        modTab[modeId]:SetActive(at)
    end
end

function My:LoadMod(modName)
    LoadPrefab(modName, GbjHandler(self.LoadModelCb, self))
end

function My:LoadModelCb(go)
    local name = go.name
    local cfg = self.getCfgByName[name]
    local gbj = self.Gbj
    local modId = cfg.id
    local TF = TransTool.Find
    local paPath = cfg.parent
    local pa = nil
    if paPath == "" then
        pa = gbj.transform
    else
        pa = TF(gbj,paPath,self.Name)
    end
    go.transform.parent = pa
    self:SetGbjPos(go,cfg)
    self.modelTab[modId] = go
    if name == StateModelCfg[5].modelName then
        self:RewardBallEff()
    end

    if name == "FX_UI_Dujie_hand" or name == "FX_UI_Dujie_hand_lv" then
        local handId = self:GetHandEff()
        self:ModelActive(false,handId)
    end
end

function My:SetGbjPos(go,cfg)
    local tranPo = cfg.pos
    local posVec = Vector3.New(tranPo[1][1],tranPo[1][2],tranPo[1][3])
    local roVec = Quaternion.New(tranPo[2][1],tranPo[2][2],tranPo[2][3])
    local scVec = Vector3.New(tranPo[3][1],tranPo[3][2],tranPo[3][3])
	go.transform.localPosition = posVec
	go.transform.localEulerAngles = roVec
    go.transform.localScale = scVec
    LayerTool.Set(go, 19)
end

--奖励小球贴图
function My:ReBallTex(texName)
    self.reTexName = texName
    AssetMgr:Load(texName, ObjHandler(self.SetIcons, self))
end

--设置贴图
function My:SetIcons(tex)
    if LuaTool.IsNull(self.rewardTexture) then
        iTrace.eError("GS","渡劫小球奖励gameobject为空")
        return
    end
    self.rewardTexture.material.mainTexture = tex
end

--isAll:任务是否全部完成
function My:SingleBallEff(index,ac)
    local ballId = index
    local ballLineId = index - 4
    self:ModelActive(ac,ballId)
    self:ModelActive(ac,ballLineId)
end

--全部特效球和线的控制
--ac:true:激活    false:隐藏
function My:AllBallEff(ac)
    local ballId = 0
    local ballLineId = 0
    for i = 12,15 do
        ballId = i
        ballLineId = i - 4
        self:ModelActive(ac,ballId)
        self:ModelActive(ac,ballLineId)
    end
end

--点击战灵动画播放流程
function My:ClickSpReward()
    local modState = self:GetModState(self.modelId)
    if modState == false then
        UITip.Error("请稍后点击")
        return
    end
    --隐藏原有模型
    self:CtrNaModel(false)

    self:ModelActive(false,5)
    self:ShowDif(false)
    -- self:ModelActive(false,6)
    -- self:ModelActive(false,7)

    --显示模型消失动画
    local hideId = self.hideId
    self:ModelActive(true,hideId)

    local cfg = self:GetCfg()    
    if cfg == nil then return end
    local tm = cfg.delayTime * 0.001
    if tm <= 0 then return end
    self:AutoTimer(tm)
end

--自动执行战灵出现动画流程
function My:AutoExe()
    self.recordIndex = self.recordIndex + 1
    local cfg = self:GetCfg()
    if cfg == nil then return end
    local id = cfg.id
    local tm = cfg.delayTime * 0.001
    if tm <= 0 then return end
    self:ModelActive(true,id)
    self:AutoTimer(tm)
end

function My:AutoTimer(tm)
    local timer = self.autoTimer
    timer:Reset()
    timer:Start(tm)
end

function My:StopTimer()
    self.autoTimer:Stop()
end

--原生角色模型
function My:CtrNaModel(ac)
    local modId = self.modelId
    self:ModelActive(ac,modId)
end

--获取播放配置
function My:GetCfg()
    local record = self.recordIndex
    if record > 4 then
        self.recordIndex = 1
        self:StopTimer()
        --显示原有模型
        self:CtrNaModel(true)
        self:ModelActive(true,5)
        self:ShowDif(true)
        return
    end
    local hideId = self.hideId
    local spBirthId = 20
    local spSkillId = 21
    local spId = self.spIdIndex --不同战灵表现
    if spId == 10101 then
        spSkillId = 21
    elseif spId == 10201 then
        spSkillId = 23
    elseif spId == 10301 then
        spSkillId = 24
    elseif spId == 10401 then
        spSkillId = 25
    elseif spId == 10501 then
        spSkillId = 26
    end
    local showId = self.showId
    local exeTab = {hideId,spBirthId,spSkillId,showId}
    local cfg = StateModelCfg[exeTab[record]]
    return cfg
end

--释放模型资源
function My:CleanData()
    for k,v in pairs(self.modelTab) do
        local name = v.gameObject.name
        AssetMgr:Unload(name,".prefab",false)
        DestroyImmediate(v.gameObject)
        self.modelTab[k] = nil
    end
end

function My:ShowBallEff(index,ac)
    -- local burstTab = self.ballBurstTab
    -- local ballTab = self.ballTab
    -- local lineTab = self.ballLineTab
    -- burstTab[index]:SetActive(ac)
    -- ballTab[index]:SetActive(ac)
    -- lineTab[index]:SetActive(ac)
end

function My:ClearTab(tab)
    for k,v in pairs (tab) do
        tab[k] = nil
    end
end

--释放奖励Texture
function My:ClearReTex()
    if self.reTexName then
        AssetMgr:Unload(self.reTexName, false)
        self.reTexName = nil
    end
end

function My:GetCfgByName()
    for i = 1,#StateModelCfg do
        local info = StateModelCfg[i]
        local name = info.modelName
        self.getCfgByName[name] = info
    end
end

function My:Dispose()
    self.recordIndex = 1
    self.modelId = nil
    self.showId = nil
    self.hideId = nil
    self:StopTimer()
    self:ClearReTex()
    self:CleanData()
    self:ClearTab(self.ballLineTab)
    self:ClearTab(self.ballBurstTab)
    self:ClearTab(self.ballTab)
    self:ClearTab(self.getCfgByName)
    TableTool.ClearUserData(self)
end

return My