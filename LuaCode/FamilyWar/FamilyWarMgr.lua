FamilyWarMgr = Super:New{Name = "FamilyWarMgr"}

local M = FamilyWarMgr

M.Green = "1"  --黄
M.Red = "2"    --紫
M.None = "3"

M.eUpdateInfo = Event()  --更新双方分数和占领点数量
M.eUpdateTrend = Event()  --更新占领进度
M.eUpdateFamWar = Event()  --更新帮派战面板
M.eUpdateRegion = Event()  --更新占领点
M.eUpdatePass = Event()    --初始化占领点进度条
M.eUpdateFWState = Event()  --更新主界面帮战按钮
M.eReadyTimeEnd = Event()   --开始倒计时结束

M.ActivityInfo = {}


function M:Init( ... )
    self:Reset()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:Reset()
   self.campDic = {}  --帮战敌我双方阵营数据
   self.campDic["0"] = {}
   self.remainTime = 0  --帮战剩余时间
   self.readyTime = 0  --帮战开始剩余时间
   self.endRankData = {}
   self.curPoint = 0
end

function M:SetPlayerTag()
    User.MapData.Tag = "FamilyWarSelf"
end

function M:SetLsnr(fn)
    fn(26100, self.RespFamilyWarScore, self)
    fn(26102, self.RespFamilyWarRank, self)
    fn(26104, self.RespFamilyWarPass, self)
    fn(26106, self.RespFamilyWarTrend, self)
    fn(26108, self.RespFamilyWarInfo, self)  
    fn(21120, self.RespFamilyWarQua, self)
    fn(21124, self.RespFamilyWarRegion, self)
end

--帮战对战信息
function M:RespFamilyWarQua(msg)
    self.eUpdateFamWar(msg)
end

--请求帮战面板信息
function M:ReqFamilyWarQua()
    local msg = ProtoPool.GetByID(21119)
    ProtoMgr.Send(msg)
end


function M:RespFamilyWarRegion(msg)
    local info = msg.info 
    local dic = self.campDic
    local id = info.id
    local val = info.val
    if id ~= 3 then     
        local data = dic[tostring(id)]
        if data then
            local list = data.occupyList
            local index = self:IndexOf(list, val)
            if index == -1 then
                table.insert(list, val)
            end
        end
    else
        local list = dic[self.Green].occupyList
        local index = self:IndexOf(list, val)
        if index ~= -1 then
            table.remove(list,index)
        else
            list = dic[self.Red].occupyList
            local index = self:IndexOf(list, val)
            if index ~= -1 then
                table.remove(list,index)
            end
        end
    end

    self.eUpdateRegion(id, val)
end

function M:RespActivityInfo(status, end_time)
    local state = status == 2
    local tmp = {}
    tmp.state = state
    tmp.eTime = end_time
    self.ActivityInfo = tmp
    self.eUpdateFWState(state)
end


--战场信息
function M:RespFamilyWarInfo(msg)
    self:Reset()
    self:SetPlayerTag()
    local list = msg.list
    local len = #list
    local dic = {}

    for i=1,len do
        local temp = {}
        temp.camp = list[i].id
        temp.familyId = list[i].family_id
        temp.familyName = list[i].family_name or ""
        temp.score = list[i].score
        temp.occupyCount = #list[i].region
        temp.occupyList = temp.occupyCount > 0 and list[i].region or {}
        dic[tostring(list[i].id)] = temp
    end
    self.campDic = dic
    self:SetWarTime(msg.open_time)
    UIMgr.Open(UIFamilyWarInfo.Name, self.OpenFamWarInfoCb, self)
end

--积分变化
function M:RespFamilyWarScore(msg)
    local dic = self.campDic
    local list = msg.list
    local len = #list
    for i=1,len do
        local key = tostring(list[i].id)
        if dic[key] then
            dic[key].score = list[i].val
            dic[key].occupyCount = list[i].type
        end
    end

    self.eUpdateInfo()
end

--结算
function M:RespFamilyWarRank(msg)
    local temp = {}
    temp.isWin = msg.winner == User.MapData.Camp
    temp.list = {}
    local list = msg.list
    local len = #list
    for i=1,len do
        local t = {}
        t.rank = list[i].rank
        t.score = list[i].score
        t.name = list[i].role_name
        t.familyName = list[i].family_name
        t.rewardList = FamilyWarRewardCfg[i].reward
        table.insert(temp.list, t)
    end
    table.sort(temp.list, function(a,b) return a.rank < b.rank end)
    self.endRankData = temp
    UIMgr.Open(UIFamilyWarEnd.Name, self.OpenFamWarEndCb, self)
end

--占领进度
function M:RespFamilyWarTrend(msg)
    local temp = {}
    temp.onwer = msg.onwer
    local dic = self.campDic
    local list = msg.info
    local len = #list
    for i=1,len do
        local camp = tostring(list[i].camp)
        dic[camp].occupyScore = list[i].score
        dic[camp].change = list[i].change
        dic[camp].trend = list[i].trend   
        --  iTrace.eError("RespFamilyWarTrend", "camp:"..camp..", score:"..list[i].score .. ", change:".. list[i].change..",trend: ".. list[i].trend )
    end
    self.eUpdateTrend()  --占领占领进度
end

function M:ReqFamilyWarPass(region, state)
    local msg = ProtoPool.GetByID(26103)
    msg.region = region
    msg.state = state
    ProtoMgr.Send(msg)
end

function M:RespFamilyWarPass(msg)
    local list = msg.list
    local len = #list
    local dic = self.campDic
    for i=1,len do
        dic[tostring(list[i].id)].occupyScore = list[i].val
	--iTrace.eError("RespFamilyWarPass","camp:"..list[i].id..", score:"..list[i].val)
    end
    self.eUpdatePass()
end


function M:ReqEnter()

    local hadJion = FamilyMgr:JoinFamily() 
    if not hadJion then
        UITip.Log("您还没有加入帮派！")
        return
    end

    local lv = ActiveInfo["10010"].needLv
    if User.MapData.Level < lv then
        UITip.Log(string.format("您的等级不足%d级，不能参与道庭战", lv))
        return
    end

    if not self.ActivityInfo.state then
        UITip.Log("不在活动时间内！")
        return
    end
    

    -- local data = FamilyMgr:GetFamilyData()
    -- if data and data.rank > 8 then
    --     UITip.Log("您的帮派没有参赛资格！")
    -- else
        SceneMgr:ReqPreEnter(30008, true, true)
    -- end  
end


--==============================--



--判断list 是否存在 val, 存在返回下标， 不存在返回-1
function M:IndexOf(list, val)
    for i=1,#list do
        if list[i] == val then
            return i
        end
    end
    return -1
end

--获取当前占领点的占领阵营
function M:CurPointOwner()
    local dic = self.campDic
    local list = dic[self.Green].occupyList
    if self:IndexOf(list, self.curPoint) ~= -1 then
        return self.Green, self.curPoint
    end

    list = dic[self.Red].occupyList
    if self:IndexOf(list, self.curPoint) ~= -1 then
        return self.Red, self.curPoint
    end

    return self.None, self.curPoint
end

function M:SetCurPoint(curPoint)
    self.curPoint = curPoint
end

--设置帮派战时间
function M:SetWarTime(stime)
    local temp = GlobalTemp["36"].Value2
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = now - stime
    self.readyTime = dValue < temp[2] and temp[2]-dValue or 0
    self.remainTime = stime + temp[1] + temp[2] - now
end

--获取绿方信息
function M:GetGreenCampData()
    return self.campDic[self.Green]
end

--获取红方信息
function M:GetRedCampData()
    return self.campDic[self.Red]
end

--获取帮派战剩余时间
function M:GetRemainTime()
    return self.remainTime
end

--获取准备剩余时间
function M:GetReadyTime()
    return self.readyTime
end


--刷新结算面板
function M:OpenFamWarEndCb(name)
    local ui = UIMgr.Get(name)
    ui:UpdateData(self.endRankData)
end

--刷新FamWarInfo
function M:OpenFamWarInfoCb(name)
    local ui = UIMgr.Get(name)
    ui:InitWarInfo()
    self:ReqFamilyWarPass(0, 1)
end

function M:Clear()
    self:Reset()
end

return M