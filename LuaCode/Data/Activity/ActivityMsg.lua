ActivityMsg = {Name="ActivityMsg"}
local My = ActivityMsg;
--活动开启列表
My.OpenActList = {}
My.CacheList = {}

My.AdvActTimeTab = {} --提前活动
My.eActivityInfo = Event()
My.eUpdateTime = Event()

My.ZXZC = 10001 --诛仙战场
My.XFLJ = 10002 --仙峰论剑
My.SWDT = 10003 --守卫道庭
My.SSLD = 10004 --蜀山论道
My.DTDT = 10006 --道庭答题
My.XYST = 10008 --逍遥神坛
My.DTDZ = 10010 --道庭大战
My.MYBS = 10011 --魔域boss
My.DTSS = 10012 --道庭神兽

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    ProtoLsnr.AddByName("m_activity_info_toc",self.RespActivity,self);
end

--活动信息反馈
function My:RespActivity(msg)
    local len = #msg.activity_list;
    if len == 0 then
        return;
    end

    for i = 1, len do
        local actInfo = msg.activity_list[i];
        local actId = actInfo.id
        local actState = actInfo.status
        local endTime = actInfo.end_time
        local strId = tostring(actId)
        local cfg = ActiveInfo[strId]
        local actName = cfg.name
        -- iTrace.eError("GS","actId== ",actId,"    actName== ",actName,"    actState== ",actState)
        if actState == 0 then
            self:StartTimer(actId,endTime)
        else
            if actInfo.id == 10001 then
                ThrUniBattle:BatTimeInfo(actInfo);
            elseif actInfo.id == 10002 then
                Peak.RespPeakActiv(actInfo.status,actInfo.end_time);
            elseif actInfo.id == 10003 then
                FamilyActivityMgr:FamilyDft(actInfo.status,actInfo.end_time);
            elseif actInfo.id == 10004 then
                AnswerMgr:RespActivInfo(actInfo);
            elseif actInfo.id == 10006 then
                FamilyAnswerMgr:RespActivInfo(actInfo.status,actInfo.end_time);
            elseif actInfo.id == 10012 then
                FamilyBossMgr:RespFamilyBossActiv(actInfo.status,actInfo.end_time);
            elseif actInfo.id == 10008 then
                TopFightMgr:RespActivInfo(actInfo.status,actInfo.end_time)
            elseif actInfo.id == 10010 then
                FamilyWarMgr:RespActivityInfo(actInfo.status,actInfo.end_time)
            elseif actInfo.id == 10011 then
                DemonMgr:RespDemonActiveInfo(actInfo)
            elseif actInfo.id == 90001 then
                FamilyEscortMgr:RespEscortActiveInfo(actInfo)
            end
            self:SetActLst(actInfo.id,actInfo.status);
            if actInfo.id ~= 90001 then
                self:UpdateCacheList(actInfo.id, actInfo.status)
            end
        end
        self.eActivityInfo(actInfo)
    end
    self:OpenMsgBox()
end

--设置活动列表
function My:UpdateCacheList(id, status)
    if status == 2 then
        -- if id ~= 10012 then
        --     TableTool.Add(self.CacheList, id)
        -- end
        TableTool.Add(self.CacheList, id)
    elseif status == 3 then
        TableTool.Remove(self.CacheList, id)
    end
end

function My:OpenMsgBox()   
    local temp = SceneTemp[tostring(User.SceneId)]
    if temp and temp.maptype == 1 then
        local acId = table.remove(self.CacheList)
        if acId == 10013 then return end  --过滤秘境探索
        self.actId = acId
        if self.actId then  
            local info = ActiveInfo[tostring(self.actId)]
            if info == nil then return end
            local str = string.format("%s已经开启，是否前往？", info.name)
            MsgBox.ShowYesNo(str,self.YesCb, self, "前往" , self.NoCb, self, "取消")
        end
    end
end

function My:YesCb()
    ListTool.Clear(self.CacheList)
    if self.actId == 10001 then --诛仙战场
        UIArena.OpenArena(4)
    elseif self.actId == 10002 then --仙峰论剑
        UIArena.OpenArena(2)
    elseif self.actId == 10003 then--仙盟守卫
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyDefendWnd.Name)
        end
    elseif self.actId == 10004 then--修仙论道
        SceneMgr:ReqPreEnter(30006, true, true) 
    elseif self.actId == 10006 then--仙盟答题
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyAnswerIt.Name)
        end
    elseif self.actId == 10012 then--仙盟Boss
        if CustomInfo:IsJoinFamily() then
            UIFamilyBossIt:OpenTab(true)
        end
    elseif self.actId == 10008 then--青云之巅
        UIMgr.Open(UITopFightIt.Name)
    elseif self.actId == 10009 then --神魔之战

    elseif self.actId == 10010 then--帮派战
        if CustomInfo:IsJoinFamily() then
            UIMgr.Open(UIFamilyWar.Name)
        end
    elseif self.actId == 10011 then --魔域禁地
        UIMgr.Open(UIDemonArea.Name)
    end
end

function My:NoCb()
    if not self.timer then
        self.timer = ObjPool.Get(iTimer)
        self.timer.complete:Add(self.CompleteCb, self)
    end
    self.timer.seconds = 0.3
    self.timer:Start()
end

function My:CompleteCb()
    self:OpenMsgBox()
end

--设置活动列表
function My:SetActLst(id,status)
    if status == 2 then
        if My.OpenActList[id] == nil then
            My.OpenActList[id] = 1;
        end
    elseif status == 3 then
        if My.OpenActList[id] ~= nil then
            My.OpenActList[id] = nil;
        end
    end
end

--活动是否开启
function My.ActIsOpen(actId)
    local lst = My.OpenActList;
    if lst == nil then
        return false;
    end
    if lst[actId] ~= nil then
        return true;
    else
        return false;
    end
end

-- 创建倒计时时间
function My:StartTimer(actId,eTime)
    local acTimeTab = self.AdvActTimeTab
    if acTimeTab[actId] == nil then
        acTimeTab[actId] = {}
    end
    if (not actId) or (not eTime) then return end
    if acTimeTab[actId].time == nil then
        acTimeTab[actId].time = ObjPool.Get(DateTimer)
    end
    local timer = acTimeTab[actId].time
    timer:Stop()
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = eTime - now
    if dValue<=0 then
        timer.remain = ""
        self:EndTime()
    else
        timer.seconds=dValue
        timer.fmtOp = 3
        timer.apdOp = 1
        timer.invlCb:Add(self.UpTime,self)
        timer.complete:Add(self.EndTime, self)
        timer:Start()
        self:UpTime()
    end
end

function My:UpTime()
    local timerTab = self.AdvActTimeTab
    for k,timer in pairs(timerTab) do
        if timer and timer.time then
            local time = timer.time
            local curTime = time.remain
            self.eUpdateTime(k,curTime,true)
        end
    end
end

function My:EndTime()
    self:StopTimer()
end

function My:StopTimer()
    local timerTab = self.AdvActTimeTab
    for k,timer in pairs(timerTab) do
        if timer and timer.time then
            local time = timer.time
            time:Stop()
            timer.time = nil
            self.AdvActTimeTab[k] = nil
            self.eUpdateTime(k,0,false)
        end
    end
end

function My:Clear()
    TableTool.ClearDic(My.OpenActList)
    TableTool.ClearDic(self.AdvActTimeTab)
    ListTool.Clear(self.CacheList)
    self.actId = nil
    self:StopTimer()
end

function My:Dispose()

end

return My;