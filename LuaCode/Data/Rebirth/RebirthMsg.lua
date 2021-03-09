RebirthMsg = {Name = "RebirthMsg"}
local My = RebirthMsg;

My.eRefresh = Event();
My.eDestinyUp = Event() 

function My:Init()
    self.RbLev = 0
    self.DestinyId = 0
    self:AddLsnr();
end

--添加协议监听
function My:AddLsnr()
    ProtoLsnr.AddByName("m_relive_info_toc",self.RespReBirth,self);
    ProtoLsnr.AddByName("m_destiny_info_toc",self.RespReDestiny,self);
    ProtoLsnr.AddByName("m_destiny_up_toc",self.RespReDestinyUp,self);
end

--转生信息返回
function My:RespReBirth(msg)
    if msg.err_code ~= 0 then
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
        return;
    end
    self.RbLev = msg.relive_level;
    self.Progress = msg.progress;
    User.MapData.ReliveLV = msg.relive_level;
    My.SetIcon();
    self.eRefresh();
    if self.RbLev >= 4 then
        UserMgr.eLvEvent()
    end
end

--天命等级上线推送
function My:RespReDestiny(msg)
    self.DestinyId = msg.destiny_id
    self.eDestinyUp()
end

--提升天命等级返回
function My:RespReDestinyUp(msg)
    if msg.err_code ~= 0 then
        UITip.Log(ErrorCodeMgr.GetError(msg.err_code));
        return;
    end
    self.DestinyId = msg.destiny_id
    self.eDestinyUp()
end

--发送转生完成
function My:SendRbDone()
    local msg = ProtoPool.Get("m_relive_up_tos");
    ProtoMgr.Send(msg);
end

--提升天命等级
function My:ReqReDestinyUp()
    local msg = ProtoPool.GetByID(21055)
	ProtoMgr.Send(msg)
end

--设置主界面图标红点
function My.SetIcon()
    if My.ChkRbReady() == true then
        SystemMgr:ShowActivity(ActivityMgr.ZS)
    else
        SystemMgr:HideActivity(ActivityMgr.ZS)
    end
end

--检查完成状态
function My.ChkRbReady()
    local rbLev = RebirthMsg.RbLev + 1;
    local prog = RebirthMsg.Progress;
    local info = Rebirth[rbLev];
    if info == nil then
        return false;
    end
    if User.MapData.Level < info.limLev then
        return false
    end
    local len = #info.targets;
    if len == prog then
        return true;
    end
    return false;
end

--转生是否在开启状态
function My:IsRbOpen()
    local rbLev = self.RbLev + 1;
    local stage = self.Progress + 1;
    local info = Rebirth[rbLev];
    if info == nil then
        return false;
    end
    if User.MapData.Level < info.limLev then
        return false;
    end
    local len = #info.targets;
    if stage <= len then
        local target = info.targets[stage];
        if target == nil then
            return false;
        end
    end
    return true;
end

function My:Clear()
    self.RbLev = 0;
    self.Progress = 0;
    self.DestinyId = 0
end

return My;