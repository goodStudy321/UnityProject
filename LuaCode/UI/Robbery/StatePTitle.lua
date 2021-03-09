require("UI/Robbery/StatePTween")

StatePTitle = Super:New{Name = "StatePTitle"}
local My = StatePTitle
My.eOnSwap = Event()

function My:Init(go,stateAct)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local USE = UITool.SetLsnrSelf
  
    self.lock = CG(UISprite,root,"lock")
    self.lock.gameObject:SetActive(false)
    self.sp = CG(UISprite,root,"sp")
    self.stateLab = CG(UILabel,root,"lab")
    self.stateSlidLab = CG(UILabel,root,"slidLab")
    self.swapBtn = TFC(root,"swap")
    self.tweenTable = CG(UITable,root,"table")
    self.tween = CG(TweenScale,root,"table/tween")
    local tweenTrans = TF(root,"table/tween")
    self.tweenAct = ObjPool.Get(StatePTween)
    self.tweenAct:Init(tweenTrans,stateAct)
    -- self.table1 = statePinfo.table1

    self.rewCount = 0

    self.ambTab = RobberyMgr.AmbNumTab

    USE(self.swapBtn,self.OnSwap,self)
    self.isPlay = false
    self.tweenIndex = 1
end

function My:OnSwap()
    local play = self.isPlay
    -- self.lock.gameObject:SetActive(play)
    
    self.tween:Play(play)
    self.isPlay = not play 
end

function My:SetTweenCall()
    self.OnPlayTweenCallback = EventDelegate.Callback(self.OnTweenFinished, self)
	EventDelegate.Add(self.tween.onFinished, self.OnPlayTweenCallback)
end

function My:OnTweenFinished()
    local index = self.tweenIndex
    if index == 2 then
        self:SetTween()
        self.tweenIndex = 1
        My.eOnSwap()
        return
    end
    local play = self.isPlay
    if play == false then 
        self.swapBtn.transform.localEulerAngles = Vector3.New(0,0,180)
    else
        self.swapBtn.transform.localEulerAngles = Vector3.New(0,0,0)
    end
    self.tweenTable:Reposition()
    My.eOnSwap()
end

function My:SetTween()
    self.tweenIndex = 2
    self.isPlay = false
    self:OnSwap()
end

function My:CloseBtn()
    self.Gbj.gameObject:SetActive(false)
end

--设置不同境界状态
--flag:  1:已突破(灰色+lock+完成标识+btn)   2：当前境界(正常色)    3：未突破(lock))
function My:SetState(flag,index)
    if flag == 1 then
        self:SetTweenCall()
        self:SetGray(self.Gbj)
        self:SetTween()
    elseif flag == 2 then
        self.isPlay = true
    elseif flag == 3 then
        self.lock.gameObject:SetActive(true)
    end
    self.swapBtn:SetActive(flag == 1)
    self:RefreshData(index)
    self:SetLockSize()
    -- self:SetReposition(flag > 1)
    self.sp.color = Color.New(1,1,1,0.01)
    self.tweenTable:Reposition()
end

--index:1 ~ #AmbitCfg
function My:RefreshData(index)
    local ambCfg = self.ambTab[index]
    local bigState = index + 10 - 1
    local propTab,rewardTab = RobberyMgr:GetStateInfo(bigState)
    if propTab == nil or rewardTab == nil then return end
    self.rewCount = #rewardTab
    local curIndex = RobberyMgr:GetCurStateIndex()
    local isGray = index < curIndex
    self:TitleData(ambCfg,index,curIndex,isGray)
    self.tweenAct:ShowProp(propTab,isGray)
    self.tweenAct:ShowReward(rewardTab,isGray)
end

function My:TitleData(ambCfg,index,curIndex,isGray)
    self.stateLab.text = ambCfg.nameOnly
    local cur,max = 0,ambCfg.floorMax
    if index < curIndex then
        cur = ambCfg.floorMax
    elseif index == curIndex then
        -- local curId = ambCfg.id
        local curCfg = RobberyMgr:GetCurCfg()
        cur = curCfg.step.k
    elseif index > curIndex then
        cur = 0
    end
    local str = string.format( "(%s/%s)",cur,max)
    self.stateSlidLab.text = str
end

function My:SetReposition(ac)
    local table1 = self.table1
    local padding = table1.padding
    local y = 0
    if ac == false then
        y = 2
    else
        y = 20
    end
    padding.y = y
    table1.padding = padding
end


--设置蒙版大小
function My:SetLockSize()
    local lockSize = {{x = 435,y = 369},{x = 435,y = 480},{x = 435,y = 589}}
    local count = self.rewCount
    local len = math.ceil(count/4)
    local lock = self.lock
    lock.width = lockSize[len].x
    lock.height = lockSize[len].y
end

--设置灰色
function My:SetGray(go)
    local tranTab = go:GetComponentsInChildren(typeof(Transform), true)
    if tranTab == nil then return end
    local len = tranTab.Length - 1
    local labCor = Color.New()
    for i = 0, len do
        local obj = tranTab[i]
        local gbj = obj.gameObject
        local sp = obj:GetComponent("UISprite")
        local lab = obj:GetComponent("UILabel")
        local color = nil
        if not LuaTool.IsNull(sp) then
            color = labCor
            color = color(0,1,1,1)
            sp.color = color
        elseif not LuaTool.IsNull(lab) then
            color = labCor
            color = color(178/255,173/255,173/255,1)
            lab.color = color
        end
    end
end

function My:Dispose()
    self.tweenIndex = 1
    if self.OnPlayTweenCallback then
        EventDelegate.Remove(self.tween.onFinished, self.OnPlayTweenCallback)
        self.OnPlayTweenCallback = nil
    end
    if self.tweenAct then
        ObjPool.Add(self.tweenAct)
        self.tweenAct = nil
    end
    self.rewCount = 0
    self.isPlay = false
    self.ambTab = nil
    TableTool.ClearUserData(self)
end