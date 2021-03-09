MissionItem = Super:New {Name = "MissionItem"}

local My = MissionItem

function My:Init(go)
    self.go=go;
    local root = go.transform
    self.root = root
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.clickIndex = 0
    self.comMisIndex = 0

    self.table = CG(UITable,root,"table")
    self.desLab = CG(UILabel,root,"des")
    self.proLab = CG(UILabel,root,"table/proLab")
    self.getRoBtn = CG(UISprite,root,"getBtn")
    self.getRoLab = CG(UILabel,root,"getBtn/lab")
    self.reIcon = CG(UITexture,root,"table/reward/icon")
    self.reNum = CG(UILabel,root,"table/reward/numLab")
    self.red = TFC(root,"getBtn/red")
    self.missionBtn = TF(root,"getBtn")
    self.reBtn = TF(root,"table/reward")
    self.flag = TF(root,"flag")
    US(self.missionBtn, self.OnClickGetMiss, self)
    US(self.reBtn, self.OnClickReBtn, self)
    -- self.go.gameObject.name = index
end

--点击奖励物品
function My:OnClickReBtn()
    local id = self.rewardId
    if id == nil then
        return
    end
    PropTip.pos = self.reBtn.transform.position
    PropTip.width = self.reIcon.width
    UIMgr.Open("PropTip", self.ShowTip, self)
end

function My:ShowTip(name)
    local ui = UIMgr.Get(name)
    local id = self.rewardId
    ui:UpData(id)
end

function My:OnClickGetMiss(obj)
    local index = tonumber(self.go.gameObject.name)
    -- 3   1   2   4
    local vec = Vector3.New()
    local vec1 = vec(380,198,0)
    local vec2 = vec(380,127,0)
    local vec3 = vec(380,58,0)
    local vec4 = vec(380,-15,0)
    local posTab = {vec2,vec3,vec1,vec4}

    local missId = self.mssId
    if missId == nil then return end
    local missid = tonumber(missId)
    local curMisInfo = RobberyMgr.RoMissionInfoTab[missid]
    if curMisInfo == nil then
        iTrace.eError("GS","获取渡劫任务为空")
        return
    end
    local curMisId = curMisInfo.missId
    local id = tostring(curMisId)
    local misCfg = RobberyMCfg[id]
    if misCfg == nil then
        iTrace.eError("GS","渡劫任务配置  RobberyMCfg，任务id:" .. id .. "不存在")
        return
    end
    if curMisInfo.status == 1 then
        if misCfg.jumpFlag > 0 then
            RobberyMgr:JumpUI(misCfg.jumpFlag)
        elseif misCfg.jumpFlag == 0 and misCfg.jumpGetWay then
            RobberyMgr:JumpGetWayUI(misCfg.jumpGetWay,posTab[index],misCfg.jumpName)
        end
        return
    elseif curMisInfo.status == 3 then
        return
    end
    -- self.clickIndex = index
    RobberyMgr:ReqMission(curMisId)
end

function My:InitData(info,smInfo,index)
    local mathToStr = math.NumToStrCtr
    self.rewardId = nil
    self.mssId = nil
    local id = info.missId
    id = tostring(id)
    -- self.go.gameObject.name = index
    self.go.gameObject:SetActive(true)
    self.mssId=id;
    local misCfg = RobberyMCfg[id]
    if misCfg == nil then
        iTrace.eError("GS","请策划检查渡劫任务配置  或 上传渡劫任务配置  任务ID==" .. id)
        return
    end
    local compType = misCfg.comType
    local desStr = misCfg.missionDes
    local proStr = ""
    if compType == 601001 then
        proStr = string.format("[00FF00FF](%s/%s)[-]",info.times,misCfg.copTarget[2].k)
    elseif compType == 507001 then
        proStr = ""
    elseif compType == 410001 then
        proStr = string.format("[00FF00FF](%s/%s)[-]",info.times,misCfg.copTarget[1].k)
    else
        local show1 = mathToStr(info.times)
        local show2 = mathToStr(misCfg.copTarget[1].k)
        proStr = string.format("[00FF00FF](%s/%s)[-]",show1,show2)
    end
    self.desLab.text = desStr
    self.proLab.text = proStr
    local reInfo = misCfg.rewardDic[1]
    local reId = reInfo.k
    local iconPath = ItemData[tostring(reId)].icon
    self.rewardId = reId
    local num = reInfo.v
    self:IsComplete(info.status,iconPath,num,smInfo,index)
    self.table:Reposition()
end

function My:IsComplete(status,iconPath,num,smInfo,index)
    if iconPath == nil then
        iTrace.eError("GS","检查渡劫任务奖励配置")
        return
    end
    if status == 1 then -- 前往任务
        self:SetRed(false)
        self:IsComState(true)
        self:SetReward(iconPath,num)
        self:SetRoIcon(1,index,smInfo)
    elseif status == 2 then --领取任务奖励
        self:SetRed(true)
        self:IsComState(true)
        self:SetReward(iconPath,num)
        self:SetRoIcon(2,index,smInfo)
    elseif status == 3 then --任务奖励已领取
        self:SetRed(false)
        self:IsComState(false)
        -- self.go.gameObject:SetActive(false)
        -- smInfo:ShowBallEff(index,true)
        local state = RobberyMgr.RobberyState
        if state == 1 or state == 5 then
            return
        end
        smInfo:SingleBallEff(index,true)
    end
end

function My:SetRoIcon(index,effIndex,smInfo)
    self.go.gameObject:SetActive(true)
    -- smInfo:ShowBallEff(effIndex,false)
    -- smInfo:SingleBallEff(effIndex,false)
    local spBgTab = {"btn_cultivate2","btn_task_none"}
    local spTab = {"前往","领取"}
    self.getRoBtn.spriteName = spBgTab[index]
    self.getRoLab.text = spTab[index]
end

--iconName:加载资源名称
function My:SetReward(iconPath,num)
    if iconPath == nil then
        return
    end
    self:UnLoadIcon()
    self.reNum.text = num
    AssetMgr:Load(iconPath,ObjHandler(self.LoadIconFunc,self))
end

function My:IsComState(isCom)
    self.missionBtn.gameObject:SetActive(isCom)
    -- self.reBtn.gameObject:SetActive(isCom)
    self.flag.gameObject:SetActive(not isCom)
end

--设置红点状态
function My:SetRed(ac)
    self.red:SetActive(ac)
end

function My:LoadIconFunc(obj)
    self.reIcon.mainTexture = obj 
    self.reIconName = obj.name
end

function My:UnLoadIcon()
    if self.reIconName then
        AssetTool.UnloadTex(self.reIconName)
        self.reIconName = nil
    end
end

function My:Dispose()
    self.clickIndex = 0
    self.rewardId = nil
    self.mssId = nil
    self.go = nil
    self:UnLoadIcon()
    -- soonTool.desCell(self.goods)
	TableTool.ClearUserData(self)
end
