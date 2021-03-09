GiftMgr = Super:New{Name = "GiftMgr"}
local My = GiftMgr
My.eGiftInfo = Event()
My.eGiftBtnInfo = Event()

function My:Init()
    self:SetLsner(ProtoLsnr.Add)
    self:SetLn("Add")
    self:Reset()
end

function My:Reset()
    self.btnState = 0
    self.roleId = 0
    self.roleName = 0
    self.roleCharge = 0
end

function My:SetLsner(fun)
    fun(28046,self.ResOutGiftInfo,self) --绝版壕礼推送
    fun(28048,self.ResOutGiftBtn,self)  --领取奖励返回
end
function My:SetLn(func)
    NewActivMgr.eUpActivInfo[func](NewActivMgr.eUpActivInfo, self.RespUpActivState, self)
end

function My:ResOutGiftInfo(msg)
    self.btnState = msg.status --按钮状态: 1 立即领取 2 已领取
    self.roleId = msg.role_id --RoleID
    self.roleName = msg.name --名字
    self.roleCharge = msg.accrecharge --累计充值数
    self.eGiftInfo()
    self:RedState()
end

function My:ResOutGiftBtn(msg)
    local error = msg.err_code
    if self:CheckErr(error) then return end
    self.btnState = msg.status  --按钮状态: 1 立即领取 2 已领取
    self.eGiftBtnInfo()
    self:RedState()
end

function My:ReqGetR()
    local msg = ProtoPool.GetByID(28047)
	ProtoMgr.Send(msg)
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Error(err)
	    return true
    end
    return false
end

function My:RespUpActivState(actionId)
    local isOpen = self:IsOpen()
    self.isOnLine = false
    if actionId == nil and isOpen then --线上推送
        self.isOnLine = true
    end
    self:RedState(actionId)
end

function My:RedState(actionId)
    local roleUseId = User.instance.MapData.UID
    roleUseId = tostring(roleUseId)
    local charRoleId = self.roleId
    if charRoleId == nil then
        charRoleId = 0
    end
    charRoleId = tostring(charRoleId)
    local btnState = self.btnState
    local id = actionId
    local isOpen = self:IsOpen()
    if (id and id == 2006 and isOpen) or (btnState == 1 and charRoleId == roleUseId) then
        OutGiftMgr:UpAction(1,true)
    elseif id == nil and isOpen then
        if self.isOnLine == true and btnState == 1 and charRoleId == roleUseId then
            OutGiftMgr:UpAction(1,true)
            self.isOnLine = false
            return
        end
        if btnState == 1 and charRoleId == roleUseId then
            OutGiftMgr:UpAction(1,true)
        elseif btnState == 2 or btnState == 3 then
            OutGiftMgr:UpAction(1,false)
        end
    end
end

function My:IsOpen()
    local isOpen = NewActivMgr:ActivIsOpen(2006) --绝版豪礼是否开启
    return isOpen
end

function My:Clear()
    self:Reset()
end

function My:Dispose()
    self:Reset()
    self:SetLn("Remove")
end

return My