RushBuyMgr = {Name="RushBuyMgr"}
local My = RushBuyMgr
local CheckErr = ProtoMgr.CheckErr

local Info = require("Data/RushBuy/RushBuyDateInfo")

My.eRushBuyInfo = Event()
My.eRushBuy = Event()
My.eRushBuyBtn= Event()
My.RushBuyList = {}

function My:Init()
    self:AddProto()
end

function My:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

function My:ProtoHandler(Lsnr)
    Lsnr(22830,self.RushBuyInfo,self) -- m_role_zero_panicbuy_info_toc  (抢购信息)
    Lsnr(22832,self.RushBuy,self)     -- m_role_zero_panicbuy_toc (抢购返回)
end

--服务端推送抢购信息(已购道具)
function My:RushBuyInfo(msg)
    local list = msg.id_list
    local rushEndTime = msg.end_time
    local len = #list
    local isShowBtn = false

    local curTime = TimeTool.GetServerTimeNow()/1000
    local date = rushEndTime - curTime
    if date > 0 and len >= 0 and len < 3 then
        isShowBtn = true
    elseif date > 0 and len >= 3 then
        isShowBtn = false
    elseif date <= 0 or date == nil then
        isShowBtn = false
    end
    local day = date/3600/24
    day = math.modf(day)
    day = day + 1
    Info.RushBuyTime = day
    self.eRushBuyBtn(isShowBtn)
    if isShowBtn == false then
        Info.RushBuyTime = nil
        return
    end

    for i = 1,len do
        local id = list[i]
        table.insert(Info.RushBuyList,id)
    end
    self.eRushBuyInfo()
    SystemMgr:ShowActivity(ActivityMgr.LYQG)
end

--抢购信息返回
function My:RushBuy(msg)
    local err = msg.err_code
    if err > 0 then
        err = ErrorCodeMgr.GetError(err)
        UITip.Log(err)
        return
    end
    local buyId = msg.id
    table.insert(Info.RushBuyList,buyId)
    self.eRushBuy(buyId)
end

--购买抢购道具
function My:ReqRushBuy(id)
    if id == nil then
        iTrace.eError("GS","发送的道具id为空，请检查原因")
        return
    end
	local msg = ProtoPool.GetByID(22831)  --m_role_zero_panicbuy_tos (抢购)
    msg.id = id
    -- iTrace.Error("GS","sendid===",id)
	ProtoMgr.Send(msg)
end

function My:Clear()
    Info:Clear()
end

function My:Dispose()
    self:RemoveProto()
end

return My


