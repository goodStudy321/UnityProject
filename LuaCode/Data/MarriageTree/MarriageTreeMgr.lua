MarriageTreeMgr = Super:New{Name = "MarriageTreeMgr"}
local M = MarriageTreeMgr

function M:Init()
    self.oneRewardList = {}
    self.dailyRewardList = {}

    self:InitOneReward()
    self:InitDailyReward()

    self.eChangeTaBtn = Event()
    self.eChangeReqBtn = Event()
    self.eChangeRewardBtn = Event()
    self.eUpdateRewardItem = Event()
    self.eShowTree = Event()
    self:SetLs("Add")
    self:SetLsner(ProtoLsnr.Add)
end

function M:SetLsner(fun)
    -- 为对方种树返回
    fun(23622,self.RespForTree,self)
    -- 姻缘树信息更新
    fun(23624,self.RespUpdataData,self)
    -- 请求赠送信息返回
    fun(23626,self.RespReqTree,self)
    --领取奖励返回
    fun(23628,self.RespReward,self)
end

function M:SetLs(key)
    MarryMgr.eMarry[key](MarryMgr.eMarry, self.ShowAllRed, self)
    MarryMgr.eDivorce[key](MarryMgr.eDivorce, self.ShowNoRed, self)
end

function M:ShowAllRed()
    self.reqAct = true
    self.taAct = true
    self.getOne = false
    self.getTwo = false
    self:SetActive()
end

function M:ShowNoRed()
    self.reqAct = false
    self.taAct = false
    self.getOne = false
    self.getTwo = false
    self:SetActive()
end

--==============================--
-- 返回
function M:RespForTree(msg)
    if msg.err_code == 0 then
        MarryInfo.data.coupleTreeEndTime = msg.couple_tree_end_time
        UITip.Log("为对方种树成功")
        self.eChangeTaBtn()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end


-- 姻缘树信息更新
function M:RespUpdataData(msg)
    MarryInfo.data.treeEndTime = msg.tree_end_time
    MarryInfo.data.treeIsAward = msg.tree_active_reward
    MarryInfo.data.treeDailyTime = msg.tree_daily_time
    self.eChangeReqBtn()
    self.eChangeRewardBtn()
    self.eShowTree()
end

function M:RespReqTree(msg)
    if msg.err_code == 0 then
        self.roldId = msg.from_role_id
        local selfRoldId = tostring(User.MapData.UID)
        local roldId = tostring(self.roldId)
        if roldId ~= selfRoldId then
            UIMgr.Open(MarrTipPanel.Name)
            MarrTipPanel:ChangeBtnLbAndLb(true,false,"您的仙侣眼巴巴的望着您，希望您为TA种下一棵象征着美满爱情的姻缘树，快快满足TA吧!","确定","取消",true)
        else
            UITip.Log("已请求")
        end
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

function M:RespReward(msg)
    if msg.err_code == 0 then
        MarryInfo.data.treeIsAward = msg.tree_active_reward
        MarryInfo.data.treeDailyTime = msg.tree_daily_time
        self.btnType = msg.type
        self.eChangeRewardBtn()
        self.eUpdateRewardItem()
        self.eShowTree()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end
--==============================--

function M:SetRoleId(roldId)
    self.roldId = roldId
end

function M:SetBtnType(num)
    self.btnType = num
end

--==============================--

function M:GetRoldId()
    return self.roldId
end

function M:GetReward()
    local sData = {}
    sData[#sData + 1] = self.oneRewardList
    for i,v in ipairs(self.dailyRewardList) do
        sData[#sData + 1] = v
    end
    return sData
end

function M:GetBtnType()
    return self.btnType
end


-- 设置红点
function M:GetStatus()
    local selfLerp = self:GetTimeLerp(1)
    local isGetisReward = MarryInfo.data.treeIsAward
    local isSame = self:isSameDay()
    if selfLerp > 0 then
        if isGetisReward == false then
            return false
        else
            return true
        end
        if isSame == true then
            return false
        else
            return true
        end
    else
        return false
    end
end

function M:InitAct()
    local couLerp = self:GetTimeLerp(0)
    local selfLerp = self:GetTimeLerp(1)
    if couLerp < 0 then
        self.taAct = true
    else
        self.taAct = false
    end
    if selfLerp < 0 then
        self.reqAct = true
    else
        self.reqAct = false
    end
end

function M:SetActive()
    local getOne = self.getOne
    local getTwo = self.getTwo
    local reqAct = self.reqAct
    local taAct = self.taAct
    if getOne == true or getTwo == true or reqAct == true or taAct == true then
        MarryMgr:SetActionDic(4,true)
    else
        MarryMgr:SetActionDic(4,false)
    end
end

-- 得到双方种树剩余时间
function M:GetTimeLerp(isSelf)
    local now = TimeTool.GetServerTimeNow()*0.001
    local endTime = nil
    if isSelf == 1 then
        endTime = MarryInfo.data.treeEndTime
    else
        endTime = MarryInfo.data.coupleTreeEndTime
    end
    local selfLerp = endTime - now
    return selfLerp
end

function M:isSameDay()
    local now = TimeTool.GetServerTimeNow()*0.001
    local year =  DateTool.GetDate(now).Year
    local month = DateTool.GetDate(now).Month
    local day = DateTool.GetDate(now).Day
    local lastGet = MarryInfo.data.treeDailyTime
    local lastyear = DateTool.GetDate(lastGet).Year
    local lastmonth = DateTool.GetDate(lastGet).Month
    local lastday = DateTool.GetDate(lastGet).Day
    if year ~= lastyear or  month ~= lastmonth or day ~= lastday then
        return false
    else
        return true
    end
end

--==============================--

function M:InitOneReward()
    self.oneRewardList = {}
    local num =  GlobalTemp["53"].Value3
    self.oneRewardList.id = 3
    self.oneRewardList.value = num
end

function M:InitDailyReward()
    self.dailyRewardList = GlobalTemp["53"].Value1
end

--==============================--
-- 请求
-- 请求为他种树
function M:ReqForTaTree()
    local msg = ProtoPool.GetByID(23621)
    ProtoMgr.Send(msg)
end

-- 请求种树
function M:ReqTree()
    local msg = ProtoPool.GetByID(23625)
    ProtoMgr.Send(msg)
end

-- 请求领取奖励
function M:ReqReward()
    local msg = ProtoPool.GetByID(23627)
    msg.type = self.btnType
    ProtoMgr.Send(msg)
end

function M:Clear()
    self.reqAct = true
    self.taAct = true
    self.getOne = false
    self.getTwo = false
end

return M