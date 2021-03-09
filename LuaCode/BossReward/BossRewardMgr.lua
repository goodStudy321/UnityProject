BossRewardMgr = Super:New{Name = "BossRewardMgr"}

local M = BossRewardMgr

M.bossRewardList = {}

M.eRefresh = Event()
M.eUpdateBtnState = Event()

function M:Init()
    self:InitData()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:SetLsnr(Lsnr)
    Lsnr(26068, self.RespBossReward, self)
    Lsnr(26074, self.RespBossRewardGet, self)
end

function M:RespBossReward(msg)
    local grade = msg.grade
    local list = self.bossRewardList
    local len = #list
    for i=1,len do
        local unit = list[i]
        if unit.id < grade then
            unit.curCount = unit.count
            unit.hadGet = 1
        elseif unit.id == grade then
            unit.hadGet = msg.got_reward
            unit.curCount = msg.kill_num
        else
            unit.hadGet = 0
        end
    end
    self:UpdateRedPoint()
    self.eUpdateBtnState(true)
    self.eRefresh()
end

function M:RespBossRewardGet(msg)
    self:CheckErr(msg.err_code)
end

function M:ReqBossRewardGet()
    local msg = ProtoPool.GetByID(26073)
    ProtoMgr.Send(msg)
end

function M:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return false
    end
    return true
end


---Init
function M:InitData()
    local cfg = BossRewardCfg
    for i=1, #cfg do 
        local unit = self:CreateUnit(cfg[i])
        table.insert(self.bossRewardList, unit)
    end
end

function M:CreateUnit(data)
    local unit = {}
    unit.id = data.id
    unit.sceneType = data.sceneType
    unit.level = data.level
    unit.rewardList = data.rewardList
    unit.address = data.address
    unit.count = data.count   --需要击败数
    unit.curCount = 0 --当前击败数
    unit.hadGet = 1  --奖励是否领取 1-已领 0-未领
    unit.bossList = {}
    local bossList = data.bossList
    for i=1,#bossList do
        local temp = MonsterTemp[tostring(bossList[i])]
        if temp then
            local boss = {}
            boss.id = temp.id
            boss.texture = temp.icon
            table.insert(unit.bossList, boss)
        end
    end
    return unit
end

--update
function M:UpdateRedPoint()
    local list = self.bossRewardList
    local state= false
    for i=1, #list do
        local unit = list[i]
        if unit.hadGet == 0 then
            state = unit.curCount == unit.count
            break
        end
    end

    if state then
		SystemMgr:ShowActivity(ActivityMgr.BossReward)
	else
		SystemMgr:HideActivity(ActivityMgr.BossReward)
	end
end


--get
function M:GetCurGold()
    local list = self.bossRewardList
    local len = #list
    local temp = list[len]
    local isDone = true
    for i=1,len do
        local unit = list[i]
        if unit.hadGet == 0 then
            temp = unit
            isDone = false
            break
        end
    end
    return temp, isDone
end

--获取当前进度和总进度
function M:GetProgress()
    local list = self.bossRewardList
    local len = #list
    local cur = len
    for i=1,len do
        local unit = list[i]
        if unit.hadGet == 0 then
            cur = i
            break
        end
    end
    return cur, len
end

--是否显示
function M:IsOpen()
    local list = self.bossRewardList
    for i=1,#list do
        local unit = list[i]
        if unit.hadGet == 0 then
            return true
        end
    end
    return false
end


function M:Clear()
    TableTool.ClearDic(self.bossRewardList)
    self:InitData()
end

return M