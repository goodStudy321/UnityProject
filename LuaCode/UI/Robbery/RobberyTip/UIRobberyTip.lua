UIRobberyTip = UIBase:New{Name = "UIRobberyTip"}
require("UI/Robbery/RobberyTip/RoTipReCell")
local My = UIRobberyTip
My.openIndex = nil
My.isNext = nil

function My:InitCustom()
    local root,des = self.root,self.Name
    local TF = TransTool.Find
    local FindC,SetB = TransTool.FindChild,UITool.SetBtnClick
    local time = 5
    local CG = ComTool.Get
    local bg = TF(root,"Bg",des)
    local tAlpha = bg:GetComponent("TweenAlpha")
    tAlpha.from = 1
    tAlpha.to = 1
    tAlpha.duration = time
    self.desLab = CG(UILabel,root,"Bg/desLab")
    self.skDesLab = CG(UILabel,root,"Bg/skLab")
    self.propLab = CG(UILabel,root,"Bg/propLab")
    self.btn = CG(BoxCollider,root,"Bg/btn")
    self.btnLab = CG(UILabel,root,"Bg/btn/Label")
    self.succ = FindC(root,"Bg/sprite1",des)
    self.other = FindC(root,"Bg/sprite2",des)
    self.timeLab = CG(UILabel,root,"Bg/timeLab")

    self.grid = CG(UIGrid,root,"Bg/scroll/grid",name)
    self.cell = TF(root,"Bg/scroll/grid/cell")
    self.cell.gameObject:SetActive(false)

    UITool.SetLsnrSelf(self.btn, self.CloseBtn, self)
    self.cellTab = {}
end

function My:OpenCustom()
    local time = 5
    self:CreateTimer()
    self:UpTimerLab(time)
    self:UpTimer(time)
    self:DiffUI()
    local smallState = RobberyMgr.StateInfoTab.smallState
    local bigState = RobberyMgr.StateInfoTab.bigState
    if smallState == nil or bigState == nil then return end
    local cur = RobberyMgr.AmbitInfo[bigState][smallState]
    if cur == nil then
        iTrace.eError("GS"," UIRobberyTip  渡劫获取当前配置错误")
        return
    end

    local cur = RobberyMgr:GetCurCfg()
    local isNext = self.isNext
    if isNext then
        cur = RobberyMgr:GetNextCfg()
    end
    local curF = cur.floorName
    self:SetCurSLab(curF)
    self:RefreshProp(cur)
    local curSId = cur.id
    local rewardTab = RobberyMgr:GetCurSReward(curSId)
    self:ShowReward(rewardTab)
end

function My:ShowReward(data)
    local len = #data
    local list = self.cellTab
    local count = #self.cellTab
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
            local go = Instantiate(self.cell)
            TransTool.AddChild(self.grid.transform,go.transform)
            go.transform.localScale = Vector3.New(0.8,0.8,0.8)
            local item = ObjPool.Get(RoTipReCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

--设置当前境界
function My:SetCurSLab(lab)
    self.desLab.text = string.format( "%s 加成",lab)
end

function My:RefreshProp(cfg)
    local props = PropTool.SwitchAttr(cfg)
    local len = #props
    if len < 1 then return end
    local str = ""
    for i = 1,len do
        local info = props[i]
        local key = info.k
        local val = info.v
        local name = PropName[key].name
        str = string.format( "%s[F4DDBDFF]%s[-] [00FF00FF]+%s[-]",str,name,val)
        if i < len then
            str = string.format("%s\n",str)
        end
    end
    self.propLab.text = str
end

--打开界面
function My:OpenRobberyTip(index,isNext)
    UIRobberyTip.openIndex = index
    UIRobberyTip.isNext = isNext
    if index == 0 then
        self:SecondsOpen()
    else
        UIMgr.Open(UIRobberyTip.Name)
    end
end

--x秒后打开界面
function My:SecondsOpen()
    local time = 1
    self.autoTimer = ObjPool.Get(iTimer)
    self.autoTimer.complete:Add(self.AutoExe,self)
    self:AutoTimer(time)
end

function My:AutoTimer(tm)
    local timer = self.autoTimer
    timer:Reset()
    timer:Start(tm)
end

function My:StopTimer()
    if self.autoTimer then
        self.autoTimer:Stop()
    end
end

function My:AutoExe()
    UIMgr.Open(UIRobberyTip.Name)
end

function My:DiffUI()
    local index = self.openIndex
    local dif = index == 0
    self.other:SetActive(dif)
    self.succ:SetActive(not dif)
    -- local btnStr = dif == true and "突破" or "关闭"
    -- local skillStr = dif == true and "获得技能" or "获得奖励"
    local btnStr = "确认"
    local skillStr = "获得奖励"
    self.btnLab.text = btnStr
    self.skDesLab.text = skillStr
end

--更新计时器
function My:UpTimer(time)
    if self.timer == nil then
        iTrace.eError("GS","没有发现计时器")
        return
    end
    local timer = self.timer
    timer.seconds = time
    timer:Start()
end

--创建计时器
function My:CreateTimer()
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown,self)
    timer.complete:Add(self.EndCountDown,self)
end

--间隔倒计时
function My:InvCountDown()
    local times = self.timer:GetRestTime()
    local time = math.floor(times)
    self:UpTimerLab(time)
end

--结束倒计时
function My:EndCountDown()
    self:CloseBtn()
end

function My:CloseBtn()
    local skillId = RobberyMgr.FlySkillId
    if skillId > 0 then
        skillId = tostring(skillId)
        local isSKill = SkillLvTemp[skillId] and 1 or 2
        if isSKill == 2 then
            -- self:RewardQUse(skillId)
            self:Close()
            return
        end
        local cfg = SkillLvTemp[skillId]
        if cfg == nil then
            iTrace.eError("GS","检查 境界配置表配置，  SkillLvTemp 不存在 id为:" .. skillId .. " 的配置")
            return
        end
        OpenMgr:OpenSkill(skillId)
    end
    self:Close()
end

function My:RewardQUse(skillId)
    local quickList = {skillId}
    local count = #quickList
	if count==0 then return end
	local type_id = quickList[1]
	local num = PropMgr.TypeIdByNum(type_id)
	table.remove(quickList,1)
	local item = UIMisc.FindCreate(type_id)
	if not item then return end
	local canquick = item.canQuick or 0
	local canuse=QuickUseMgr.CanUse(item)
	if QuickUseMgr.isBegin==false then return end
	if canquick==1 and canuse==true and num>0 then 
        QuickUseMgr.OpenQuickUse(type_id,num)
    end
end


function My:ConDisplay()
	do return true end
end

--初始化计时器文本
function My:UpTimerLab(time)
    -- self.timeLab.text = "(" .. time .. "秒后关闭)"
    self.timeLab.text = time .. "S"
end

function My:CellToPool()
    if self.cellTab then
        for k,v in pairs(self.cellTab) do
            v:Dispose()
            ObjPool.Add(v)
            self.cellTab[k] = nil
        end
    end
end

--清理缓存
function My:Clear()
    self.desLab = nil
    self.propLab = nil
    self.openIndex = nil
    self.isNext = nil
    self:CellToPool()
end

--重写释放资源
function My:CloseCustom()  --DisposeCustom   CloseCustom
    local roMgr = RobberyMgr
    self:Clear()
    self:StopTimer()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    roMgr.FlySkillId = 0
    roMgr:ReqRobbery()
    local sceneId = User.SceneId
    if sceneId == roMgr.RobberySceneId then
        SceneMgr:QuitScene()
	end
end

return My