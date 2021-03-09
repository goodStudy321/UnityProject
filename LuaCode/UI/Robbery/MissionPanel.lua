require("UI/Robbery/MissionItem")

MissionPanel = Super:New{Name = "MissionPanel"}
local My = MissionPanel
--记录任务位置信息
My.RoMPosTab = {}

local MIIT = MissionItem
--境界任务格子
My.mssItemTab={};
My.mssDataTab={};
My.MissionTab = {}
My.eMissionUpdate = Event()

function My:Init(go,stateM)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    self.stateMInfo = stateM

    self.itemNew = TF(root,"mItem",name)
    self.itemNew.gameObject:SetActive(false)
    -- 3   1   2   4
    local vec = Vector3.New()
    local vec1 = vec(365,218,0)
    local vec2 = vec(365,148,0)
    local vec3 = vec(365,78,0)
    local vec4 = vec(365,8,0)
    -- self.RoMPosTab = {vec2,vec3,vec1,vec4}
    self.RoMPosTab = {vec1,vec2,vec3,vec4}
    self:LoadRoMi()
    self:SetEvent("Add")
end

function My:SetEvent(fn)
    RobberyMgr.eUpdateMissionInfo[fn](RobberyMgr.eUpdateMissionInfo, self.SetMissionItNew, self)
end

function My:Open()
    self.Gbj.gameObject:SetActive(true)
end

--加载任务item
function My:LoadRoMi()
    local go = self.itemNew
    local posTab = self.RoMPosTab
    for i = 1,4 do
        local trans = Instantiate(go)
        trans.gameObject:SetActive(true)
        local t = trans.transform
        local itemSp = t:GetComponent("UISprite")
        if i == 1 or i == 3 then
            itemSp.enabled = false
        end
        t.transform:SetParent(self.Gbj)
        t.localScale = Vector3.one
        t.localPosition = posTab[i]
        local obj = ObjPool.Get(MissionItem)
        obj:Init(trans)
        trans.gameObject.name = i
        table.insert(self.mssItemTab,obj)
    end
    self:SetMissionItNew()
end

function My:SetMissionItNew()
    local smInfo = self.stateMInfo
    if smInfo == nil then
        iTrace.eError("GS","渡劫控制特效模块为空，需检查")
        return
    end
    self:ClearMissTab()
    self:HideMissItem(smInfo)

    local temp = RobberyMgr.RoSortMissinTab
    if temp == nil then return end

    local index = 0
    local missState = RobberyMgr.RobberyState
    local isComAll = false
    if missState == 1 or missState == 5 then
        isComAll = true
    end
    local ballTemp = {}


    local len = #temp
    local itemTab = self.mssItemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            local v = temp[i]
            if v then
                table.insert(self.MissionTab,v)
                local ballEffId = i + 11
                ballTemp[ballEffId] = ballEffId
                itemTab[i]:InitData(v,smInfo,ballEffId)
            end
        elseif i <= count then
            local info = itemTab[i]
            info.go.gameObject:SetActive(false)
        end
    end
   
    local isShowAll = false
    local roState = RobberyMgr.RobberyState
    if roState == 1 or roState == 5 then
        isShowAll = true
    end
    if isShowAll then
        for i = 12,15 do
            if ballTemp[ballId] == nil then
                smInfo:SingleBallEff(i,true)
            end
        end
        smInfo:ModelActive(false,5)
        smInfo:ModelActive(false,6)
        smInfo:ModelActive(false,7)
    else
        smInfo:ModelActive(true,5)
    end
    self.eMissionUpdate()
end

function My:ClearMissTab()
    local len = #self.MissionTab
    while len > 0 do
        table.remove(self.MissionTab,len)
        len = #self.MissionTab
    end
end

function My:HideMissItem(smInfo)
    -- local tab = self.mssItemTab
    -- local len = #tab
    -- for i = 1,len do
    --     local info = tab[i]
    --     info.go.gameObject:SetActive(false)
    -- end
    smInfo:AllBallEff(false)
end

function My:ClearTab()
    if self.mssItemTab then
        for k,v in pairs(self.mssItemTab) do
            v:Dispose()
            ObjPool.Add(v)
            self.mssItemTab[k] = nil
        end
    end
end

function My:CloseC()
    self.Gbj.gameObject:SetActive(false)
end

function My:Dispose()
    self:ClearTab()
    self:ClearMissTab()
    self:SetEvent("Remove")
    self:CloseC()
    TableTool.ClearUserData(self)
end