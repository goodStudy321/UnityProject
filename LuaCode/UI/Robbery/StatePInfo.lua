require("UI/Robbery/StatePTitle")

StatePInfo = Super:New{Name = "StatePInfo"}
local My = StatePInfo

function My:Init(go,stateAct)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    self.curSelect = nil
    self.curIndex = nil
    self.propLabTab = {}
    self.panel = CG(UIPanel,root,"scrollV")
    self.scrollV = CG(UIScrollView,root,"scrollV")
    self.table1 = CG(UITable,root,"scrollV/table")
    -- self.centerChild = CG(UICenterOnChild,root,"scrollV/table")
    self.title = TF(root,"scrollV/table/title")
    self.title.gameObject:SetActive(false)
    self.stateP = stateAct
    self.items = {}
    self:SetLsnr("Add")

    self.autoTimer = ObjPool.Get(iTimer)
    self.autoTimer.complete:Add(self.ResetAutoPosition,self)
end

function My:SetLsnr(key)
    StatePTitle.eOnSwap[key](StatePTitle.eOnSwap, self.ResetPosition, self)
end

function My:OpenGbj()
    self.Gbj.gameObject:SetActive(true)
end

function My:CloseBtn()
    self.Gbj.gameObject:SetActive(false)
end

function My:SetSlider()
    local cur = RobberyMgr:GetCurCfg()
    local bigState = RobberyMgr:GetBigState(cur.id)
    local index = (bigState - 10) + 1
    local curItem = self.items[index]
    local curPos = curItem.Gbj.localPosition()
end

--初始化
function My:InitState()
    local item = self.title
    local ambTab = RobberyMgr.AmbNumTab
    local len = #ambTab
    local Ins = GameObject.Instantiate
    local itemLen = #self.items
    if len == itemLen then
        return
    end
    for i = 1,len do
        local data = ambTab[i]
        local go = Ins(item)
        self:AddItem(i,data,go)
    end
    self:RefreshItem()
end

function My:AddItem(index,data,go)
    if go == nil then return end
    go.gameObject:SetActive(true)
    local trans = go.transform
    local it = ObjPool.Get(StatePTitle)
    it:Init(go,self.stateP)
    it.Gbj.name = index
    table.insert(self.items,it)
    TransTool.AddChild(self.table1.transform,trans)
end

--刷新数据
function My:RefreshItem()
    local itemTab = self.items
    local len = #itemTab
    local index = RobberyMgr:GetCurStateIndex()
    for i = 1,len do
        local item = itemTab[i]
        if i < index then
            item:SetState(1,i)
        elseif i == index then
            item:SetState(2,i)
        elseif i > index then
            item:SetState(3,i)
        end
    end
    self:AutoResetPos()
end

function My:ResetPosition()
    self.table1:Reposition()
end

function My:ResetAutoPosition()
    self.table1:Reposition()
    self:SetCurCenter()
end

function My:AutoResetPos()
    local timer = self.autoTimer
    local time = 0.5
    timer:Reset()
    timer:Start(time)
end

function My:SetCurCenter()
    local index = RobberyMgr:GetCurStateIndex()
    local ambTab = RobberyMgr.AmbNumTab
    local len = #ambTab
    if index <= 3 or index >= (len-2) then
        return
    end
    local item = self.items[index]
    if item == nil then
        return
    end
    local pos = item.Gbj.transform.localPosition
    local y = pos.y
    local centerY = y + 85
    self.panel.clipOffset = Vector2.New(0,centerY)
    centerY = math.abs(centerY)
    self.panel.transform.localPosition = Vector3.New(0,centerY,0)
    -- self.scrollV:ResetPosition()
end

function My:StopTimer()
    self.autoTimer:Stop()
end

function My:ItemToPool()
    for k,v in pairs(self.items) do
        ObjPool.Add(v)
        self.items[k] = nil
    end
end

function My:Dispose()
    self:StopTimer()
    self:SetLsnr("Remove")
    self.stateP = nil
    self.curIndex = nil
    self.curSelect = nil
    self:ItemToPool()
    TableTool.ClearUserData(self)
end