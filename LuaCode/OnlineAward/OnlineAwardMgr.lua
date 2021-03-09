--[[
 	authors 	:Liu
 	date    	:2018-5-24 12:00:08
 	descrition 	:在线奖励管理
--]]

OnlineAwardMgr = {Name = "OnlineAwardMgr"}

local My = OnlineAwardMgr
My.State = false
local Info = require("OnlineAward/OnlineAwardInfo")

function My:Init()
    Info:Init()
    self:AddLnsr()
    self.eUpOnlineInfo = Event()
    self.eGetAward = Event()
end

--添加监听
function My:AddLnsr()
	self:SetLnsr(ProtoLsnr.Add)
end

--移除监听
function My:RemoveLsnr()
	self:SetLnsr(ProtoLsnr.Remove)
end

--设置监听
function My:SetLnsr(func)
    func(20362,self.RespOnlineInfo, self)
    func(20364,self.RespGetAward, self)
end

--响应在线奖励信息
function My:RespOnlineInfo(msg)
    Info.isAll = 0
    Info.onlineTime = msg.online_time
    for i,v in ipairs(msg.list) do
        Info:SetData(i, v)
    end
    self.State = (Info.isAll==0)
    self.eUpOnlineInfo(Info.awardList)
end

--请求领取在线奖励
function My:ReqGetLvAward(minute)
    local msg = ProtoPool.GetByID(20363)
    msg.minute = minute
	ProtoMgr.Send(msg)
end

--响应领取在线奖励
function My:RespGetAward(msg)
    local err = msg.err_code
	if (err>0) then
        UITip.Error(ErrorCodeMgr.GetError(err))
		return
    end
    Info.isAll = msg.is_all
    Info.onlineTime = msg.online_time
    self.eGetAward(Info.isAll)
end

--清理缓存
function My:Clear()
    Info:Clear()
    self.State = false
end

--释放资源
function My:Dispose()
    self:RemoveLsnr()
	TableTool.ClearFieldsByName(self,"Event")
end

return My