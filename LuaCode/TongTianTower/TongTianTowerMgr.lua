--[[
    通天宝塔活动管理器
]]

TongTianTowerMgr = Super:New{Name = "TongTianTowerMgr"};
local My = TongTianTowerMgr;

My.eGetAward = Event();
My.eUpAction = Event();
function My:Init()
    self.activInfo = nil;
    self.layer = 1;
    self.pool = 1;
    self.awardItemId = 0;
    self.awardItem ={k = 0,v = 0,b = false};
    self.awardList = {};
    --套序号
    self.configNum = 0;
    --self.configNum = 20090101;
    
    
    self:SetLsnr(ProtoLsnr.Add);
end

function My:SetLsnr(fun)
    fun(26494, self.ResqInfo, self);
    fun(26496, self.ResqDrawInfo, self);
end

--获取活动信息
function My:GetActivInfo()
    self.activInfo = NewActivMgr:GetActivInfo(2009);
    self.configNum = self.activInfo.configNum;
end

function My:ActionState()
    local isShow = false;
    local actId = ActivityMgr.TTBT;
    for k,v in pairs(PropMgr.tb8Dic) do
        isShow = true
        break
    end
    if isShow == true then
        SystemMgr:ShowActivity(actId);
    else
        SystemMgr:HideActivity(actId);
    end
    return isShow
end

--打开面板
function My:OpenUI()
    UIMgr.Open(UITongTianTower.Name);
end

--上线推送
function My:ResqInfo(msg)
    self.layer = msg.layer;
    self.pool = msg.pool;
    My.eUpAction();
    My:ActionState();
end

--请求抽奖
function My:ReqAward()
    local msg = ProtoPool.GetByID(26495);
    ProtoMgr.Send(msg);
end

--清空列表
function My:ClearList()
    for i,v in ipairs(self.awardList) do
        self.awardList[i]= nil;
    end
    
end

--响应抽奖
function My:ResqDrawInfo(msg)
    local error = msg.err_code;
    local cfg = TongTianTowerCfg;
    if error ~= nil and error > 0 then
        local errString = ErrorCodeMgr.GetError(error);
        UITip.Error(errString);
    else
        local id = msg.id;
        self.awardItemId = id;
        self.layer = msg.layer;
        self.pool = msg.pool;
        self.awardItem.k = cfg[tostring(id)].itemId;
        self.awardItem.v = cfg[tostring(id)].count;
        self.awardItem.b = false;
        local item = {k = cfg[tostring(id)].itemId,
                      v = cfg[tostring(id)].count,
                      b = false}
        table.insert(self.awardList, item);
        My.eGetAward();
        My.eUpAction();
    end
end


function My:Clear()
    self.layer = 1;
    self.pool = 1;
    self:ClearList();
    self.awardItem ={k = 0,v = 0,b = false};
    self.awardItemId = 0;
    
end

return My;