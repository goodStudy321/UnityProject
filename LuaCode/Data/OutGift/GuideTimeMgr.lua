GuideTimeMgr = {Name = "GuideTimeMgr"}

local My = GuideTimeMgr

My.eUpdateAction = Event()

function My:Init()
    self:Reset()
    LuaUIEvent.euionclick:Add(self.OnUIClick, self)
    -- Hangup.eUpdateAutoStatus:Add(self.RespUpdateAutoStatus, self)
    EventMgr.Add("RoleLogin", EventHandler(self.RoleLogin, self))
end

function My:Reset()
    self.starTime = 0
    self.totalTime = 180
    self.isCanUpdate = false
end

function My:RespUpdateAutoStatus()
	local isHgp = Hangup:GetAutoHangup();
    local isStf = Hangup:GetSituFight();
    local isPause = Hangup:IsPause()
	iTrace.eError("GS","isHgp===",isHgp,"   isStf==",isStf,"  isPause==",isPause)
end

function My:OnUIClick()
    self.starTime = 0
end

function My:ResetUpdate()
    self.starTime = 0
end

function My:RoleLogin()
    self.isCanUpdate = true
end

function My:Update()
    local isUpdate = self.isCanUpdate
    if isUpdate then
        self.starTime = self.starTime + Time.deltaTime
        if self.starTime >= self.totalTime then
            self.eUpdateAction()
            self.starTime = 0
        end
    end
end

--清理缓存
function My:Clear()
    self:Reset()
end

--释放资源
function My:Dispose()
    self:Reset()
    LuaUIEvent.euionclick:Remove(self.OnUIClick, self)
end

return My