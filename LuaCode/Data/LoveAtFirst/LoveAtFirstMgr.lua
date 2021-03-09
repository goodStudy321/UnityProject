--[[
    一见钟情活动管理
]]
LoveAtFirstMgr = Super:New{Name = "LoveAtFirstMgr"}
local My = LoveAtFirstMgr;

My.eRed=Event()
My.eUpdateBtnState = Event();
My.eGetAward = Event();
function My:Init()
    self.award1State = false;
    self.award2State = false;
    self.type = 0;
    self:SetLsnr(ProtoLsnr.Add);
end

function My:SetLsnr(fun)
    fun(25002, self.ResqInfo, self);
    fun(25012, self.ResqAward, self);
end

function My:ResqInfo(msg)
    self.award1State = msg.login_reward1;
    self.award2State = msg.login_reward2;
end

function My:ReqAward(type)
    local msg = ProtoPool.GetByID(25011);
    msg.type = type;
    ProtoMgr.Send(msg);
end

function My:ResqAward(msg)
    local error = msg.err_code;
    if error ~= nil and error > 0 then
        local errStr = ErrorCodeMgr.GetError(error);
        UITip.Error(errStr);
    else
        local type = msg.type;
        self.type = type
        if type == 1 then
            self.award1State = not self.award1State;
        end
        if type == 2 then
            self.award2State = not self.award2State;
        end
        My.eUpdateBtnState();
        My.eGetAward(type);
        My:UpdateAction();
    end
end
    
function My:UpdateAction()
    local showRed = false;
    local award1 = self.award1State;
    if award1 == false then
        showRed = true;
    end

    local award2 = self.award2State;
    if MarryInfo.data.coupleInfo ~= nil then
        if award2 == false then
            showRed = true;
        end
    end
    My.eRed(showRed,1)
end

function My:Clear()
    
end

return My;