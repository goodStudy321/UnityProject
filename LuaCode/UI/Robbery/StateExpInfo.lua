require("UI/Robbery/StateExpProp")
require("UI/Robbery/StateExpCell")
StateExpInfo = Super:New{Name = "StateExpInfo"}
local My = StateExpInfo

function My:Init(go,stateAct)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find

    local lvTab = {des = "当前等级：",cur = 0,next = 0,des2 = "",add = "+",flag = "%"}
    local exp = {des = "经验：",cur = 0,next = 0,des2 = "",add = "+",flag = "%"}

    local warTab = {des = "当前战力：",cur = 0,next = 0,des2 = "万",add = "+",flag = "%"}
    local warExp = {des = "经验：",cur = 0,next = 0,des2 = "",add = "+",flag = "%"}

    local spTab = {des = "当前战灵：",cur = 0,next = 0,des2 = "",add = "+",flag = "%"}
    local spExp = {des = "经验：",cur = 0,next = 0,des2 = "",add = "+",flag = "%"}

    self.propTemp = {lvTab,exp,warTab,warExp,spTab,spExp}

    self.tExpLab = CG(UILabel,root,"expLab")
    self.cExpLab = CG(UILabel,root,"getExp")
    self.slidSp = CG(UISprite,root,"SlidBg/slid")
    self.labPrefab = TF(root,"des")
    self.spGrid = CG(UIGrid,root,"scroll/grid")
    self.spCell = TF(root,"scroll/grid/cell")
    self.labPrefab.gameObject:SetActive(false)
    self.spCell.gameObject:SetActive(false)
    local vec = Vector3.New()
    local v1 = vec(0,0,0)
    local v2 = vec(0,-28,0)
    local v3 = vec(0,-85,0)
    local v4 = vec(0,-114,0)
    local v5 = vec(0,-172,0)
    local v6 = vec(0,-202,0)
    self.pPosTab = {v1,v2,v3,v4,v5,v6}

    self.statePInfo = stateAct

    self.sortSpCfg = self:SortSpCfg()
    self.propTab = {}
    self.spItems = {}

    self.TotalTime = 5
    self.isShowExp = false

    self.autoTimer = ObjPool.Get(iTimer)
    self.autoTimer.invlCb:Add(self.AutoInvl,self)
    self.autoTimer.complete:Add(self.AutoExe,self)

    self:AutoTimer(self.TotalTime)
    self:RefreshData()
end

function My:AutoInvl()
    if self.isShowExp == false then
        if self.statePInfo.prayMInfo == nil then
            return
        end
        self.statePInfo.prayMInfo.flyExpAct:ForwardPos()
        self.isShowExp = true
    end
    local times = self.autoTimer.cnt
    local total = self.TotalTime
    local rate = times/total
    self.slidSp.fillAmount = rate
end

function My:AutoExe()
    if self.isShowExp == true then
        if self.statePInfo.prayMInfo == nil then
            return
        end
        self.statePInfo.prayMInfo.flyExpAct:ReverPos()
        self.isShowExp = false
    end
    local tm = self.TotalTime
    if tm <= 0 then return end
    self:AutoTimer(tm)
end

function My:AutoTimer(tm)
    local timer = self.autoTimer
    timer:Reset()
    timer:Start(tm,0.05)
end

function My:StopTimer()
    self.autoTimer:Stop()
end


function My:SortSpCfg()
    local tabTemp = {}
    for k,v in pairs(SpiriteCfg) do
        table.insert(tabTemp,v)
    end
    table.sort(tabTemp,function(a,b) return a.spiriteId < b.spiriteId end)
    return tabTemp
end

function My:RefreshData()
    self:RefreshTExpAdd()
    self:RefreshGetExp()
    self:RefreshProp()
    self:ShowReward()
end

--总经验加成 = 世界等级加成 + 战力加成 + 战灵加成
function My:RefreshTExpAdd()
    local worldLvAdd = 0
    local warAdd = 0
    local warSpAdd = 0
    local warId = tostring(PrayMgr.closeWarId)
    local spId = tostring(PrayMgr.closeSpId)
    local worldLv = FamilyBossInfo.worldLv
    local userLv = User.MapData.Level
    local tempLv = worldLv-userLv
    if userLv >= 110 and tempLv > 10 then
        worldLvAdd = math.min(tempLv * 6,300)
    else
        worldLvAdd = 0
    end
    if CloseExpCfg[warId] then
        warAdd = CloseExpCfg[warId].add
    end
    if CloseExpCfg[spId] then
        warSpAdd = CloseExpCfg[spId].add
    end
    local tAdd = worldLvAdd+warAdd+warSpAdd
    PrayMgr.totalAdd = tAdd
    local str = string.format("[F9AB47]总经验加成：[-][00FF00]%s%s[-]",tAdd,"%")
    self.tExpLab.text = str
end

--当前经验收益
function My:RefreshGetExp()
    -- local curExp = PrayMgr.curCloseExp
    local curExp = PrayMgr:GetTotalExp()
    local str = string.format("[F9AB47]当前经验收益：[-][00FF00]%s/%s秒[-]",curExp,self.TotalTime)
    self.cExpLab.text = str
end

function My:RefreshProp()
    local props = self.propTemp
    local len = #props
    -- local len = 6
    if len < 1 then return end
    local list = self.propTab
    local pos = self.pPosTab
    local count = #self.propTab
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            self:SetPropData(i)
            list[i]:SetCurPLab(props[i],i)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.labPrefab)
            TransTool.AddChild(self.Gbj.transform,go.transform)
            go.transform.localPosition = pos[i]
            local item = ObjPool.Get(StateExpProp)
            item:Init(go)
            item:SetActive(true)
            self:SetPropData(i)
            item:SetCurPLab(props[i],i)
            table.insert(list, item)
        end
    end
end

--index:1 ~ #self.propTemp
--local lvTab = {des = "当前等级:",cur = 0,next = 0,des2 = "级"}
function My:SetPropData(index)
    local temp = self.propTemp[index]
    local userLv = User.MapData.Level
    local warId = PrayMgr.closeWarId
    local spId = PrayMgr.closeSpId
    if warId == 0 or spId == 0 then
        warId = 101
        spId = 201
    end
    if index == 1 then --等级
        temp.cur = userLv
        temp.next = userLv + 1
    elseif index == 2 then --经验
        temp.cur = LvCfg[tostring(userLv)].closeExp
        if LvCfg[tostring(userLv + 1)] then
            temp.next = LvCfg[tostring(userLv + 1)].closeExp
        else
            temp.next = LvCfg[tostring(userLv)].closeExp
        end
    elseif index == 3 then --战力
        temp.cur = CloseExpCfg[tostring(warId)].val
        if CloseExpCfg[tostring(warId + 1)] then
            temp.next = CloseExpCfg[tostring(warId + 1)].val
        else
            temp.next = CloseExpCfg[tostring(warId)].val
        end
    elseif index == 4 then --战力经验加成
        temp.cur = CloseExpCfg[tostring(warId)].add
        if CloseExpCfg[tostring(warId + 1)] then
            temp.next = CloseExpCfg[tostring(warId + 1)].add
        else
            temp.next = CloseExpCfg[tostring(warId)].add
        end
    elseif index == 5 then--战灵
        temp.cur = CloseExpCfg[tostring(spId)].val
        if CloseExpCfg[tostring(spId + 1)] then
            temp.next = CloseExpCfg[tostring(spId + 1)].val
        else
            temp.next = CloseExpCfg[tostring(spId)].val
        end
    elseif index == 6 then--战灵经验加成
        temp.cur = CloseExpCfg[tostring(spId)].add
        if CloseExpCfg[tostring(spId + 1)] then
            temp.next = CloseExpCfg[tostring(spId + 1)].add
        else
            temp.next = CloseExpCfg[tostring(spId)].add
        end
    end
end

function My:ShowReward()
    local data = self.sortSpCfg
    local len = #data
    local list = self.spItems
    local count = #self.spItems
    if len < 1 then return end
    local max = count >= len and count or len
    local min = count + len - max
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.spCell)
            TransTool.AddChild(self.spGrid.transform,go.transform)
            local item = ObjPool.Get(StateExpCell)
            item:Init(go)
            local box = go.transform:GetComponent("BoxCollider")
            UITool.SetLsnrSelf(box,self.ClickBox,self,"StateReCell",false)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.spGrid:Reposition()
end

function My:ClickBox(obj)
    local strName = obj.gameObject.name
    local name = tonumber(strName)
    local spCfg = SpiriteCfg[strName]
    
end

function My:ItemToPool()
    for k,v in pairs(self.propTab) do
        ObjPool.Add(v)
        self.propTab[k] = nil
    end
    for k,v in pairs(self.spItems) do
        ObjPool.Add(v)
        self.spItems[k] = nil
    end
    for k,v in pairs(self.sortSpCfg) do
        self.sortSpCfg[k] = nil
    end
    
end

function My:Dispose()
    self.isShowExp = false
    self.statePInfo = nil
    self.TotalTime = 0
    self:StopTimer()
    self:ItemToPool()
    TableTool.ClearUserData(self)
end