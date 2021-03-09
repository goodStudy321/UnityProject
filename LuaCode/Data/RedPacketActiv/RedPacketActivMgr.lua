--[[
    全服红包活动
]]

RedPacketActivMgr = Super:New{Name = RedPacketActivMgr};
local My = RedPacketActivMgr;

My.eSayOtherInfo = Event();
My.eGetAward = Event();
My.eUpdateRed = Event();
My.InitState = 0;
My.eCheckBtn = Event();
function My:Init()
    self.redPacketDic = {};
    self.redPacketList = {};

    self.waitTime = 0;
    
    self:SetLsnr(ProtoLsnr.Add);
end


function My:SetLsnr(fun)
    fun(24950, self.ResqRedInfo, self);
    fun(24962, self.ResqAward, self);
    fun(24964, self.ResqSayOtherInfo, self);
    fun(24958, self.DelRedP, self);
end

--删除红包数据
function My:DelRedP(msg)
    local list = msg.packet_ids;
    for i,v in ipairs(list) do
        self.redPacketDic[tostring(v)] = nil;
        for n,m in ipairs(self.redPacketList) do
            if tonumber(v) == tonumber(m.id) then
                table.remove(self.redPacketList, n);
                break;
            end
        end
    end
    if #self.redPacketList > 0 then
        table.sort(self.redPacketList, function(a,b) return tonumber(a.id) > tonumber(b.id) end);
    end
    self:UpAction();
    My:eUpdateRed();
    My.eCheckBtn();
end



--红包数据
function My:ResqRedInfo(msg)
    local list = msg.red_packets;
    for i,v in ipairs(list) do
        local redId = tostring(v.packet_id);
        local item = {id = v.packet_id;
                        startTime = v.start_time;
                        endTime = v.end_time;
                        amount = v.amount;
                        piece = v.piece;
                        goldType = v.bind;
                        contentTbl = {}  
                    }

        for i = 1, #v.packet_list do
            local contentData = self:GetContent(v.packet_list[i]);
            if tonumber(contentData.roleId) > 1 then
                item.contentTbl[#item.contentTbl + 1] = contentData;
            end
        end

        self.redPacketDic[redId] = item;
        local isHave,index = self:IsHaveRed(tonumber(redId));
        if isHave then
            self.redPacketList[index] =item;
        else
            table.insert(self.redPacketList, item);
        end
      
    end    
    table.sort(self.redPacketList, function(a,b) return tonumber(a.id) > tonumber(b.id) end);
    self:UpAction();
    My:eUpdateRed();
    My.eCheckBtn();
    self:TimeInit();
    My.InitState = 1;
end

function My:IsHaveRed(redId)
    if #self.redPacketList > 0 then
        for i,v in ipairs(self.redPacketList) do
            if tonumber(redId) == tonumber(v.id) then
                return true, i;
            end
        end
    end
    return false;
end


--领取红包
function My:ReqAward(id)
    local msg = ProtoPool.GetByID(24961)
    msg.packet_id = tonumber(id);
    ProtoMgr.Send(msg);
end

--领取返回
function My:ResqAward(msg)
    local err = msg.err_code;
    if err ~=nil and err > 0 then
        local errStr = ErrorCodeMgr.GetError(err);
        UITip.Error(errStr);
    else
        local redPacket = msg.red_packet;

        local redId = tostring(redPacket.packet_id);
        

        local item = {id = redPacket.packet_id;
                        startTime = redPacket.start_time;
                        endTime = redPacket.end_time;
                        amount = redPacket.amount;
                        piece = redPacket.piece;
                        goldType = redPacket.bind;
                        contentTbl = {}
                    }
                    
        for i = 1, #redPacket.packet_list do
            local contentData = self:GetContent(redPacket.packet_list[i]);
            if tonumber(contentData.roleId) > 1 then
                item.contentTbl[#item.contentTbl + 1] = contentData;
            end
        end

        
        
        self.redPacketDic[redId] = item;
        for i,v in ipairs(self.redPacketList) do
            if tonumber(redId) == tonumber(v.id) then
                self.redPacketList[i] = item;
                break;
            end
        end

        My.eGetAward(item);
        EventMgr.Trigger("NewRedPContList");
        self:UpAction();
        My.eCheckBtn();
    end
end


function My:GetContent(data)
    local tb = {};
    tb.id = data.id;
    tb.name = data.name;
    tb.roleId = data.role_id;
    tb.icon = data.icon;
    tb.amount = data.amount;
    return tb;
end

function My:GetRedCount()
    local count = 0;
    for k,v in pairs(self.redPacketDic) do
        count = count + 1;
    end
    return count;
end

--查看他人信息
function My:ReqSayOtherInfo(id)
    local msg = ProtoPool.GetByID(24963)
    msg.packet_id = tonumber(id);
    ProtoMgr.Send(msg);
end

--查看信息返回
function My:ResqSayOtherInfo(msg)
    local err = msg.err_code;
    if err ~=nil and err > 0 then
        local errStr = ErrorCodeMgr.GetError(err);
        UITip.Error(errStr);
    else
        local list = msg.list;
        local id =msg.packet_id;
        local redId = tostring(id);

        local selfContent = self.redPacketDic[redId].contentTbl;
        selfContent ={}
        for i = 1, #list do
            local contentData = self:GetContent(list[i]);
            if tonumber(contentData.roleId) > 1 then
                selfContent[#selfContent + 1] = contentData;
            end
        end

        My.eSayOtherInfo(msg.packet_id);
    end
end

--红包领取数量
function My:GetRedNum(id)
    local redId = tostring(id);
    local data = self.redPacketDic[redId];
    if not data then return end 
    local num = #data.contentTbl;

    return num;
end

--获取红包数据
function My:GetRedPacketData(id)
    local redId = tostring(id);
    local data = self.redPacketDic[redId];
    return data;
end

function My:Update()
    if My.InitState == 1 then
        local dT = Time.deltaTime;
        self.waitTime = self.waitTime + dT;
        if self.waitTime > 1 then 
            self.waitTime = 0;
            self:UpAction();
        end
    end
end

--红包的领取状态
--返回5个列表：1、未发送；2、未领取；3、已领取；4、已领完；5、已过期
function My:GetAllRedState()
    local retTbl1 = {};
	local retTbl2 = {};
	local retTbl3 = {};
    local retTbl4 = {};
    local retTbl5 = {};

    for k,v in pairs(self.redPacketDic) do
        local nowTime = TimeTool.GetServerTimeNow()*0.001;

        if v.startTime - nowTime > 0 then
            retTbl1[#retTbl1 + 1] = v;
        else
            if v.endTime - nowTime > 0 and v.startTime - nowTime < 0 then
                if v.piece == self:GetRedNum(tostring(v.id)) then
                    retTbl4[#retTbl4 + 1] = v;
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
                            retTbl3[#retTbl3 + 1] = v;
                        else
                            retTbl2[#retTbl2 + 1] = v;
                        end
                    end
                end
            else
                retTbl5[#retTbl5 + 1] = v;
            end   
        end
    end
    return retTbl1, retTbl2, retTbl3, retTbl4, retTbl5;
end

--红点
function My:UpAction()
    local retTbl1, retTbl2, retTbl3, retTbl4, retTbl5 = self:GetAllRedState();
    local hasAction = false;
    if #retTbl2 > 0 then
        hasAction = true; 
        My.eCheckBtn();
    end
    LvAwardMgr:UpAction(9,hasAction);
end


--活动时间
function My:TimeInit()
    local data = NewActivMgr:GetActivInfo(2011);
    if not data then
        self:CompleteCb();
        return ;
    end 
    local endTime = data.endTime;
    local seconds =  endTime-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end
function My:CompleteCb()
    self:Clear();
    self:UpAction();
    My.eCheckBtn();
end

function My:InvlCb()
end

--清理
function My:Clear()
    self.redPacketDic = {};
    self.redPacketList = {};
    --self:SetLsnr(ProtoLsnr.Remove);
end


return My;