
--[[
    首冲弹窗
]]--

UIFirstSmall = UIBase:New{Name = "UIFirstSmall"}
local My = UIFirstSmall
local aMgr = Loong.Game.AssetMgr
require("UI/UIOpenService/UIFirstModel")

local T = TransTool.FindChild

function My:InitCustom()
    local trans = self.root
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    self.timeLab = CG(UILabel, trans, "tran/timeLab", des)
    -- self.UIModel = ObjPool.Get(UIFirstModel)
    -- self.UIModel:Init(TF(trans,"UIModel")) --武器放置的位置
    self.Model  = TF(trans,"tran/UIModel")

    UITool.SetBtnClick(trans, "tran/CloseBtn", des, self.OnCloseClick, self)
    UITool.SetBtnClick(trans, "tran/PayBtn", des, self.OpenRecharge, self) --跳转充值的按钮
end

function My:OpenCustom()
    self:InitModel()
    local time = 30
    self:CreateTimer()
    self:UpTimerLab(time)
    self:UpTimer(time)
end

function My:OpenFirsySmall()
    local isShield = FirstPayMgr:IsCanShield()
    if isShield == true then
        return
    end
    
    self.autoTimer = ObjPool.Get(iTimer)
    self.autoTimer.complete:Add(self.AutoExe,self)
    self:AutoTimer(1)
end

function My:AutoTimer(tm)
    local timer = self.autoTimer
    timer:Reset()
    timer:Start(tm)
end

function My:StopTimer()
    self.autoTimer:Stop()
end

function My:AutoExe()
    UIMgr.Open(UIFirstSmall.Name)
end

function My:InitModel()
    local clothesName = ""
    local n = FirstPayCfg[1]
    -- if User.MapData.Sex == 1 then
    --     clothesName = n.CPCloOne
    -- else
    --     clothesName = n.CPCloTwo
    -- end
    local weaPath = self:ReturnPath(n.Weapon1)
    LoadPrefab(weaPath, GbjHandler(self.SetWeaponMod, self))
end

function My:SetWeaponMod(go)
    self:ClearWeaponMod()
    self.curWeaponMod = go
    go.transform:SetParent(self.Model)
    go.transform.localPosition =  Vector3.zero
    go.transform.localScale = Vector3.one
    go.transform.localRotation = Quaternion.Euler(0,0,0)
end

function My:ReturnPath(ID)
    id = tostring(ID)
    local modBase = RoleBaseTemp[id]
    if modBase == nil then return nil end
    local modPath = modBase.uipath
    if modPath ==nil then
        modPath = modBase.path        
        if modPath == nil then return end
    end
    return modPath
end


function My:ClearWeaponMod()
    if self.curWeaponMod then
        AssetMgr:Unload(self.curWeaponMod.name, ".prefab", false)
        Destroy(self.curWeaponMod)
        self.curWeaponMod = nil
    end
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

--初始化计时器文本
function My:UpTimerLab(time)
    local timeLb = self.timeLab
    if not LuaTool.IsNull(timeLb) then
        timeLb.text = time .. "秒之后自动关闭"
    end
end

--结束倒计时
function My:EndCountDown()
    self:Close()
end

--打开首充界面
function My:OpenRecharge()
    UIFirstPay:OpenFirsyPay()
    self:Close()
end

--关闭界面
function My:OnCloseClick()
    self:Close()
end

--清理缓存
function My:Clear()
    self.UIModel = nil
end

function My:Dispose()
    self:Clear()
    self:StopTimer()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    self:ClearWeaponMod()
end

return My