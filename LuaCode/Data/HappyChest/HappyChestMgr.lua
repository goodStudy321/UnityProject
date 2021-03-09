
--[[
Creat By LiZhengDong
--]]

HappyChestMgr = Super:New{Name = "HappyChestMgr"}

local My = HappyChestMgr

function My:Init()
    self:AddLsnr()
    self.sysID = 2008
end

--存入活动信息
function My:SaveActivInfo(activInfo)
    self.actInfo = activInfo;
    local info = self.actInfo
    self.configNum = info.configNum
end


-- 获取充值条件
function My:GetPayCondition()
    local conditionList = {}
    local configNum = self.configNum
    local len = #HappyChestCfg
    for i, v in ipairs(HappyChestCfg) do
        if v.configNum == configNum then
            table.insert(conditionList, v.payCondition)
        end
    end
    return conditionList
end

-- 获取奖励cell的数据
function My:GetCellData()
    local roomList = {}
    local configNum = self.configNum
    local len = #HappyChestCfg
    for i, v in ipairs(HappyChestCfg) do
        if v.configNum == configNum then
            table.insert(roomList, v)
        end
    end
    return roomList
end



--获取属于哪个大奖对应的奖励(弃用)
function My:GetCellRewardData(accrecharge)
    local configNum = self.actInfo.configNum
    local data = {}
    for i, v in ipairs(HappyChestCfg) do
        if configNum == v.configNum and v.accrecharge == accrecharge then
            data = v.award
        end
    end
    return data
end


--判断系统是否已开启
--return:true(已开启)
function My:IsOpen()
    local info = self.actInfo
    local state = info and info.val or 2
    return (state == 1)
end

--获取结束时间
function My:GetEndTime()
    local info = self.actInfo
    local tm = info and info.endTime or 0
    return tm
end

function My:GetStartTime()
    local info = self.actInfo
    local tm = info and info.startTime or 0
    return tm
end

function My:AddLsnr()
    self.eUpLab = Event() --更新元宝数量事件
    self.eUpBox = Event()
    self.eUpBtns = Event()
    self.eUpCell = Event()
    local Add = ProtoLsnr.Add
    Add(28050, self.RespInfo, self)
    Add(28052, self.RespBtns, self)
end

--响应欢乐宝箱信息
function My:RespInfo(msg)
    if not self.accrecharge then
        self:UpRedDot()
    end

    self.accrecharge = msg.accrecharge
    self.rewardData = msg.reward
    if self.rewardData[1].val == 1 or self.rewardData[2].val == 1 or self.rewardData[3].val == 1 then
        self:UpRedDot()
    end
    if self.rewardData[1].val == 2 and self.rewardData[2].val == 2 and self.rewardData[3].val == 2 then
        self:DelRedDot()
    end
    --self.eUpBtns(self.rewardData)
    self.eUpCell()
    self.eUpBox() -- 充值完后派发刷新Box事件
    self:UpIngot(msg) -- 充值完后派发刷新元宝数量事件
end

-- 时间结束后玩家还在线，更新时间文本状态
function My:UpTimeLab()
    local status = self.status
    if status == 1 then
        self.eUpTimeLab()
    end
end

-- 充值完后派发刷新元宝数量事件
function My:UpIngot(msg)
    if msg.accrecharge then
        self.eUpLab(msg.accrecharge)
    end
end

-- 响应点击领取后返回
function My:RespBtns(msg)
    self.rewardData = msg.reward
    local reward = self.rewardData
    self.eUpBtns(reward)
end
-- 点击领取后请求领取
function My:ReqGet(id)
    local msg = ProtoPool.GetByID(28051)
    msg.id = id
    ProtoMgr.Send(msg)
end

-- 红点判断
function My:RedPoint()
    local rewardData = self.rewardData
    for i, v in ipairs(rewardData) do
        if rewardData[i].val == 1 then
            self:UpRedDot()
            return
        elseif rewardData[i].val == 2 then
            self:DelRedDot()
        end
    end
end

--初始化红点
function My:UpRedDot()
    local actId = ActivityMgr.HLBX
    local state = ActivityMgr:CheckOpenForLvId(actId)
    if state then
        SystemMgr:ShowActivity(actId)
    end
end

-- 删除红点
function My:DelRedDot()
    local actId = ActivityMgr.HLBX
    SystemMgr:HideActivity(actId)
end

function My:Reset()
    self.accrecharge = 0
    self.rewardData = nil
end

function My:Clear()
    self:Reset()
    UIMgr.Close("UIHappyChest")
end

return My