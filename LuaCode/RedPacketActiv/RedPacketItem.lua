--[[
    
]]
RedPacketItem = Super:New{Name = "RedPacketItem"};
local My = RedPacketItem;

function My:Init(go)
    self.go = go;
    local trans = go.transform;

    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local USS = UITool.SetLsnrSelf;

    self.bg1Obj = TFC(trans, "Panel1/bg1");
    self.sayOtherBtnObj = TFC(trans, "Panel1/SayOtherBtn");
    self.timeLabel1Obj = TFC(trans, "Panel1/TimeLabel1");
    self.timeLabel2Obj = TFC(trans, "Panel1/TimeLabel2");
    self.timeLabel3Obj = TFC(trans, "Panel1/TimeLabel3");
    self.getBtnObj = TFC(trans, "Panel1/GetBtn");
    self.panel1 = TFC(trans, "Panel1");
    self.panel1:SetActive(true);

    self:HideObj();
    self.headIconTex = CG(UITexture, trans, "HeadSprite/Icon");
    self.timeLabel1 = CG(UILabel, trans, "Panel1/TimeLabel1");
    self.timeLabel2 = CG(UILabel, trans, "Panel1/TimeLabel2");
    self.timeLabel3 = CG(UILabel, trans, "Panel1/TimeLabel3");

    USS(self.sayOtherBtnObj, self.OnSayOtherInfo, self, nil, false);
    USS(self.getBtnObj, self.OnGetAward, self, nil, false);

    
    --领取状态 1、未发送；2、未领取；3、已领取；4、已领完；5、已过期
    self.state = 1;

    self.redData = nil;

    self:SetLuaEvent("Add");
    
end

function My:SetLuaEvent(fn)
    RedPacketActivMgr.eSayOtherInfo[fn](RedPacketActivMgr.eSayOtherInfo, self.showInfo, self);
    RedPacketActivMgr.eGetAward[fn](RedPacketActivMgr.eGetAward, self.UpdateRed, self);
    --RedPacketActivMgr.eGetAward[fn](RedPacketActivMgr.eGetAward, self.GetRed, self);
    

end

function My:SetRedState()
    local nowTime = TimeTool.GetServerTimeNow()*0.001;
    local v = self.redData;

    if v.startTime - nowTime > 0 then
        self.state = 1;
    else
        if v.endTime - nowTime > 0 and v.startTime - nowTime < 0 then
            if v.piece == RedPacketActivMgr:GetRedNum(tostring(v.id)) then
                self.state = 4;
            else
                if v.contentTbl ~= nil then
                    local hasGet = false;
                    for i = 1,#v.contentTbl do
                        local getData = v.contentTbl[i];
                        local id = tonumber(tostring(User.instance.MapData.UID))
                        if tonumber(getData.roleId) == id then
                            hasGet = true;
                            break;
                        end
                    end
        
                    if hasGet == true then
                        self.state = 3;
                    else
                        self.state = 2;
                    end
                end
            end
        else
            self.state = 5;
        end   
    end 
end

--显示
function My:ShowItem(state)
    self.go:SetActive(state);
end

--更新红包
function My:UpdateRed(data)
    if self.redData == nil or self.redData.id == data.id then
        self.redData = data;
        self:SetShowState();
        self:ShowTime();
    end
end

function My:SetShowState()
    self:SetRedState();
    self:HideObj();
    local state = self.state;
    if state == 2 then
        self.timeLabel1Obj:SetActive(true);
        self.getBtnObj:SetActive(true);
    elseif state == 3 or state == 5 or state == 4 then
        self.sayOtherBtnObj:SetActive(true);
        self.timeLabel2Obj:SetActive(true);
    elseif state == 1 then
        self.bg1Obj:SetActive(true);
        self.timeLabel3Obj:SetActive(true);
    end
end


function My:HideObj()
    self.bg1Obj:SetActive(false);
    self.sayOtherBtnObj:SetActive(false);
    self.timeLabel1Obj:SetActive(false);
    self.timeLabel2Obj:SetActive(false);
    self.timeLabel3Obj:SetActive(false);
    self.getBtnObj:SetActive(false);
end

--倒计时
function My:ShowTime()
    local data = self.redData;
    if not data then return end
    local nowTime = TimeTool.GetServerTimeNow()*0.001;
    local endTime = data.endTime;
    local startTime = data.startTime;
    local seconds = startTime - nowTime;
    if seconds <= 0 then
        self:SetShowState();
        seconds = endTime - nowTime;
    else
        self:SetShowState();
    end
    self:StartTime(seconds);
end

function My:StartTime(sec)
    if not sec then return end
    if not self.timer then
        self.timer=ObjPool.Get(DateTimer);
        self.timer.invlCb:Add(self.UpTime,self);
        self.timer.complete:Add(self.EndTime, self);
    end
    local timer = self.timer;
    timer:Stop();
    if sec <= 0 then
        timer.remain = "";
        self:SetShowState();
        self:EndTime();
    else
        timer:Reset();
        timer.seconds = sec;
        timer.fmtOp = 3;
        timer.apdOp = 1; 
        timer:Start();
        self:UpTime();
    end
end

function My:UpTime()
    local timeStr = string.format("%s", self.timer.remain);
    
    self.timeLabel1.text = timeStr;
    self.timeLabel2.text = timeStr;
    self.timeLabel3.text = timeStr;
end

function My:EndTime()
    if self.state == 5 then
        self.timer:Stop();
        self.timeLabel2.text = "已过期";
    else
        self:ShowTime();
    end
end

--查看他人信息
function My:OnSayOtherInfo()
    RedPacketActivMgr:ReqSayOtherInfo(self.redData.id);
end

--领取
function My:OnGetAward()
    UIGiftMoneyWnd.openRedPId = tonumber(self.redData.id);
    UIGiftMoneyWnd.autoGetRedP = true;
    UIGiftMoneyWnd.isRedActiv = true;
    UIMgr.Open(UIGiftMoneyWnd.Name);
end

--显示领取信息
function My:showInfo(id)
    UIGiftMoneyWnd.openRedPId = tonumber(id);
    UIGiftMoneyWnd.showInfo = true;
    UIGiftMoneyWnd.isRedActiv = true;
    UIMgr.Open(UIGiftMoneyWnd.Name);
    
end

function My:GetRed(data)
    
    
    -- UIGiftMoneyWnd.openRedPId = tonumber(data.id);
    -- UIGiftMoneyWnd.showInfo = true;
    -- UIGiftMoneyWnd.isRedActiv = true;
    -- UIMgr.Open(UIGiftMoneyWnd.Name);
end

function My:Dispose()
    self:SetLuaEvent("Remove");
    if self.timer then
        self.timer:AutoToPool();
    end
    self.timer = nil;
end

return My;