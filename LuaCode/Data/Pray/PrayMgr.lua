PrayMgr = Super:New{Name = "PrayMgr"}
local M = PrayMgr

M.eChangeRes = Event()
M.eUpdataData = Event()

function M:Init()
    self.todayTimes = 0      -- 今日剩余次数
    self.allTimes = 0      --总祈福次数
    self.addTimes = 0     --增加次数
    self.copper = 0       -- 金币数

    self.totalAdd = 0  --总经验加成

    self.OffLineExp = 0 --离线经验
    self.OffLineTime = 0  --离线时间
    self.OldLv = 0
    self.NewLv = 0
    self.Illusion = 0 --幻力
    self.Intensify = 0 --天机勾玉可以领取的数量

    self.BGold = 0 --绑元
    self.BCopper = 0 --银两
    self.Box = 0 --宝箱


    self.closeWarId = 0 --战力加成id
    self.closeSpId = 0 --战灵加成id
    self.curCloseExp = 0 --当前经验收益

    -- self.eChangeRes = Event()
    -- self.eUpdataData = Event()
    self:SetLsner(ProtoLsnr.Add)
end

function M:SetLsner(fun)
    fun(23060,self.ResPrayInfo,self)
    fun(23062,self.ResRewardExp,self) --上线推送离线经验
    fun(23058,self.ResReward,self)
end

-- 设置红点
-- function M:SetAction(isShow)
--     local actId = ActivityMgr.QF
--     if isShow == true then
--         SystemMgr:ShowActivity(actId)
--     else
--         SystemMgr:HideActivity(actId)
--     end
-- end

-----------------协议----------------------
function M:ResPrayInfo(msg)
    self.todayTimes = msg.today_times
    self.allTimes = msg.all_times
    self.closeWarId = msg.power_add
    self.closeSpId = msg.war_spirit_add
    self.curCloseExp = msg.exp
    self.addTimes = msg.add_times
    self.allTimes = self.allTimes + self.addTimes
    if self.todayTimes == 0 then
        -- LvAwardMgr:UpAction(5,true)
    end
    self.eChangeRes()
end

function M:ResRewardExp(msg)
    self.OffLineExp = msg.exp
    self.OffLineTime = msg.time
    self.OldLv = msg.old_level
    self.NewLv = msg.now_level
    self.Illusion = msg.illusion --幻力
    self.Intensify = msg.nat_intensify --天机勾玉可以领取的数量
    self.BGold = msg.mining_bind_gold --绑元  mining_bind_gold
    self.BCopper = msg.mining_bind_copper --银两  mining_bind_copper
    self.Box = msg.family_box --宝箱   family_box
    self.canOpenUI = true
    if not NewActivMgr.RecordTabUI or #NewActivMgr.RecordTabUI == 0 then
        local active = UIMgr.GetActive(UIOffLineTip.Name)
        if active == -1 then
            UIMgr.Open(UIOffLineTip.Name)
        end
    end
end

function M:ResReward(msg)
    local expC = nil
    local cop = nil
    if msg.err_code == 0 then
        self.awardList = {}
        self.petList = {}
        self.copper = msg.copper
        self.exp = msg.exp
        expC = msg.exp
        cop = msg.copper
        local rewardList = msg.reward
        local pet_goods = msg.pet_goods
        self.todayTimes = msg.today_times
        self.allTimes = msg.all_times
        for i,v in ipairs(rewardList) do
            self:SetReward(v,self.awardList)
        end
        for i,v in ipairs(pet_goods) do
            self:SetReward(v,self.petList)
        end
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
    self.eUpdataData()
    local active = UIMgr.GetActive(UIRetreatAward.Name)
    if active == -1 then
        UIMgr.Open(UIRetreatAward.Name)
    end
end

function M:ReqReward()
    local msg = ProtoPool.GetByID(23057)
    ProtoMgr.Send(msg)
end
------------------------------------------------------------

function M:SetReward(list,dataList)
    local data = {}
    data.id = list.type_id
    data.num = list.num
    data.bind = list.bind
    table.insert(dataList, data)
end

function M:GetRewardList()
    return self.awardList
end

function M:GetPetList()
    return self.petList
end

function M:GetCoin()
    return self.copper
end

function M:GetExp()
    if self.exp == nil then
        return 0
    else
        return self.exp
    end
end

-- 获得每日可闭关次数
function M:GetBaseTimes()
    local curVip = VIPMgr.GetVIPLv()
    local addTime = self.addTimes
    local curTimer = 0
    local baseTime = GlobalTemp["139"].Value2[1]
    curTimer = curTimer + addTime
    if curVip ~= 0  then
        curTimer = VIPLv[curVip+1].arg26 + baseTime + curTimer
    else
        curTimer = baseTime + curTimer
    end
    local resTimes = curTimer - self.todayTimes
    if resTimes < 0 then
        resTimes = 0
    end
    return curTimer,resTimes
end

-- 获得当前可闭关次数、剩余次数、所花费金币数
function M:GetData()
    local curTimes,resTimes = self:GetBaseTimes()
    local times = self.todayTimes + 1
    if not PrayNumCfg[tostring(times)] then return end
    local icon = 10--PrayNumCfg[tostring(times)].moneyNum   moneyNum字段已经删除
    local exp = PrayNumCfg[tostring(times)].expNum
    return curTimes,resTimes,icon,exp
end

-- 获得实际闭关次数
function M:GetTimes()
    return self.allTimes
end

-- 获得闭关总次数
function M:GetAllTimes()
    local bsae = GlobalTemp["139"].Value2[2]
    if self.allTimes > bsae then
        return bsae
    else
        return self.allTimes
    end
end

function M:IsOpen()
    local isOpen = OpenMgr:IsOpen("55")
    return isOpen
end

--获取闭关时间
function M:GetOffTime()
    local bsae = GlobalTemp["139"].Value2[2]
    local allTime = self:GetTimes()
    if allTime <= bsae then
        allTimes = allTime + 60 - 1
    else
        allTimes = bsae + 60
    end
    return allTimes
end

--获取每五秒获得的总经验
function M:GetTotalExp()
    local time = 5
    local exp = 0
    local useLv = User.MapData.Level
    useLv = tostring(useLv)
    local closeExp = LvCfg[useLv].closeExp
    local tAdd = self.totalAdd
    tAdd = tAdd * 0.01
    exp = closeExp*(1+tAdd) * time
    return exp
end

function M:Clear()
    self.todayTimes = 0
    self.allTimes = 0
    self.addTimes = 0 
    self.totalAdd = 0
    self.OffLineExp = 0
    self.OffLineTime = 0
    self.OldLv = 0
    self.NewLv = 0
    self.Illusion = 0 --幻力
    self.Intensify = 0 --天机勾玉可以领取的数量
    self.BGold = 0 --绑元
    self.BCopper = 0 --银两
    self.Box = 0 --宝箱
    self.copper = 0
    self.closeWarId = 0
    self.closeSpId = 0
    self.curCloseExp = 0
    self.canOpenUI = false
end

return M