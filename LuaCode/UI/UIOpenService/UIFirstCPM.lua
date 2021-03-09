
--[[
    首冲弹窗
]]--

UIFirstCPM = UIBase:New{Name = "UIFirstCPM"}
local My = UIFirstCPM
local aMgr = Loong.Game.AssetMgr
require("UI/UIOpenService/UIFirstModel")
My.eDispose = Event()

local T = TransTool.FindChild

function My:InitCustom()
    local trans = self.root
    -- local pa = FirstPayMgr.CPMPa
    -- if pa == nil then
    --     return
    -- end
    -- trans.transform.parent = pa
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    self.timeLab = CG(UILabel, trans, "timeLab", des)
    -- self.UIModel = ObjPool.Get(UIFirstModel)
    -- self.UIModel:Init(TF(trans,"UIModel")) --武器放置的位置
    self.Model  = TF(trans,"UIModel")

    UITool.SetBtnClick(trans, "CloseBtn", des, self.OnCloseClick, self)
    UITool.SetBtnClick(trans, "PayBtn", des, self.OpenRecharge, self) --跳转充值的按钮
end

function My:OpenCustom()
    self:InitModel()
    local time = 10
    self:CreateTimer()
    self:UpTimerLab(time)
    self:UpTimer(time)
end

function My:OpenFirsyCPM()
    local isShield = FirstPayMgr:IsCanShield()
    if isShield == true then
        return
    end
    UIMgr.Open(UIFirstCPM.Name)
end

function My:InitModel()
    local clothesName = ""
    local n = FirstPayCfg[1]
    if User.MapData.Sex == 1 then
        clothesName = n.CPCloOne
    else
        clothesName = n.CPCloTwo
    end
    self.weaponName = n.CPMWeapon
    aMgr.LoadPrefab(clothesName,GbjHandler(self.SetModel,self))
end

function My:SetModel(go)
    self:ClearModel()
    AssetMgr:SetPersist(go.name, ".prefab",true)
    self.curModel = go
    go.transform:SetParent(self.Model)
    go.transform.localPosition =  Vector3.zero
    go.transform.localScale = Vector3.one
    go.transform.localRotation = Quaternion.Euler(0,0,0)
    local root = go.transform:GetChild(0)
    local trans = root:GetChild(0)
    self.weaponTrans = T(trans,"Bip001 Prop1").transform
    aMgr.LoadPrefab(self.weaponName,GbjHandler(self.SetWeaponMod,self))
end

function My:ClearModel()
    if self.curModel then
        AssetMgr:Unload(self.curModel.name, ".prefab", false)
        Destroy(self.curModel)
        self.curModel = nil
    end
end

function My:SetWeaponMod(go)
    self:ClearWeaponMod()
    AssetMgr:SetPersist(go.name, ".prefab",true)
    self.curModel = go
    go.transform:SetParent(self.weaponTrans)
    go.transform.localPosition =  Vector3.zero
    go.transform.localScale = Vector3.one
    go.transform.localRotation = Quaternion.Euler(0,0,0)
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
    --self.timeLab = nil
    self.UIModel = nil
end

function My:Dispose()
    self:Clear()
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    self:ClearModel()
    self:ClearWeaponMod()
end

return My