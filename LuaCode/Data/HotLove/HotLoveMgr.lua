--[[
    全程热恋活动管理
]]
HotLoveMgr = Super:New{Name = "HotLoveMgr"}
local My = HotLoveMgr;

My.eUpdateAward = Event();
My.eUpdateCond = Event();
My.eRed = Event();
My.eUpdateBtn = Event();
function My:Init()


    self.taskList = {};
    self.rewarList = {};
    self.money = 0;
    self:SetLsnr(ProtoLsnr.Add);
end


function My:SetLsnr(fun)
    fun(26498, self.ResqInfo, self);
    fun(26506, self.ResqChange, self);
    fun(26508, self.ResqAward, self);
    
end

function My:ResqInfo(msg)

    local list = msg.list;
    for i,v in ipairs(list) do
        local info = self:SetCondInfo(v.id);
        local item = {id = v.id;
                    count = v.val;
                    finishNum = info.finishNum;
                    content = info.content;
                    taskId = info.taskId;        
        }
        table.insert(self.taskList, item);
    end
    table.sort(self.taskList, function(a,b) return a.id > b.id end);


    local rewarList = msg.reward;
    for i,v in ipairs(rewarList) do
        local info = self:SetAwardInfo(v.id);
        local item = {id = v.id;
                    state = v.val;
                    needNum = info.needNum;
                    awards = info.awards;
        }
        table.insert(self.rewarList, item);
    end
    table.sort(self.rewarList, function(a,b) return a.id > b.id end);
    local money = msg.money;
    self.money = money;
   
    self:UpdateBtnState();
    My.eUpdateBtn();
    self:IsShowRed();
end

--设置奖励数据
function My:SetAwardInfo(id)
    local cfg = HotLoveAwardCfg;
    return cfg[id];
end

--设置任务
function My:SetCondInfo(id)
    local cfg = HotLoveCfg;
    return cfg[id];
end

function My:ResqChange(msg)
    local list = msg.list;
    local money = msg.money;
    self.money = money;
    for i,v in ipairs(list) do
        local info = self:SetCondInfo(v.id);
        local item = {id = v.id;
                    count = v.val;
                    finishNum = info.finishNum;
                    content = info.content;
                    taskId = info.taskId;        
        }
        for m,n in ipairs(self.taskList) do
            if n.id == v.id then
                self.taskList[m] = item;
                break;
            end
        end
        --My.eUpdateCond(item);
        
        
    end
    
    self:UpdateBtnState();
    My.eUpdateBtn();
    self:IsShowRed();
end

function My:UpdateBtnState()
    for i,v in ipairs(self.rewarList) do
        if v.state ~= 3 then
            if self.money >= v.needNum then
                self.rewarList[i].state = 2;
            end
        end
    end
end

function My:IsShowRed()
    local isShow = false;
    for i,v in ipairs(self.rewarList) do
        if v.state == 2 then
            isShow = true;
            break;
        end
    end
    My.eRed(isShow,3);
    return isShow;
end

--领取奖励
function My:ReqAward(id)
    local msg = ProtoPool.GetByID(26507);
    msg.id = id;
    ProtoMgr.Send(msg);
end
--领取返回
function My:ResqAward(msg)
    local err = msg.err_code;
    if err ~= nil and err > 0 then
        local errStr = ErrorCodeMgr.GetError(err);
        UITip.Error(errStr);
    else
        local id = msg.id;
        for m,n in ipairs(self.rewarList) do
            if n.id == id then
                self.rewarList[m].state = 3;
                My.eUpdateAward(self.rewarList[m]);
                break;
            end
        end
        self:IsShowRed();
    end
end

function My:Clear()
    self.taskList = {};
    self.rewarList = {};
    self.money = 0;
end

return My;