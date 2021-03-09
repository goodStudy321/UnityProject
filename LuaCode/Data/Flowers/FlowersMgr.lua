--region FlowersMgr.lua
--Date
--此文件由[HS]创建生成

FlowersMgr = {Name = "FlowersMgr"}
local M = FlowersMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

M.eReceive = Event()
M.eSend=Event()
M.ReceiveInfo = {}

M.FriendID = nil

function M:Init()  
    self:AddProto()
end

function M:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(23752, self.RespFlowerSend, self)	
	Lsnr(23754, self.RespFlowerReceive, self)	
	Lsnr(23756, self.RespFlowerKiss, self)	
	Lsnr(23760, self.RespCharm, self)	
end
--[[#############################################################]]--
--送花返回
function M:RespFlowerSend(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	M.eSend()
    self:OpenUI(2)
    --[[
	    local id = msg.to_role_id
	    local t = msg.type_id
        local num = msg.num
        local value = msg.is_anonymous
    ]]--
end

--收到鲜花
function M:RespFlowerReceive(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
    end
	self.ReceiveInfo.PID = msg.from_role_id
	self.ReceiveInfo.PName = msg.from_role_name
	self.ReceiveInfo.IID = msg.type_id
    self.ReceiveInfo.Num = msg.num
    self.ReceiveInfo.IsAnonymous = msg.is_anonymous
	FlowersMgr:OpenUI(3)
    --table.insert(self.ReceiveList, data)
    --self.eReceive()
end

--回吻返回
function M:RespFlowerKiss(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
    end
    UITip.Error("回吻成功")
end

--魅力值更新
function M:RespCharm(mgr)
	local charm = mgr.charm
end
--[[#############################################################]]--

--送花
function M:ReqFlowerSend(id, t, num, value)
	local msg = ProtoPool.GetByID(23751)
	msg.to_role_id = id
	msg.type_id = t
    msg.num = num
    msg.is_anonymous = value
	Send(msg)
end

--回吻
function M:ReqFlowerKiss(id)
	local msg = ProtoPool.GetByID(23755)
	msg.to_role_id = id
	Send(msg)
end
--[[#############################################################]]--

--打开UI
--- select , 1.送花 2.送花协议返回 3.收花
function M:OpenUI(select, id)
    self.Select = select
    self.FriendID = id
    UIMgr.Open(UIFlowers.Name,self.OpenUICallback,self)
end

function M:OpenUICallback()
    local ui = UIMgr.Get(UIFlowers.Name)
    if not ui then return end
    if not self.Select then return end
    ui:SelectV(self.Select)
    self.Select = nil
end

--[[#############################################################]]--

--清理缓存
function M:Clear()
    TableTool.ClearDic(self.ReceiveInfo)
end

--释放资源
function M:Dispose()
    self:RemoveProto()
end

return M
