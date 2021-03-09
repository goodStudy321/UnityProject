--[[
 	authors 	:Liu
 	date    	:2019-07-01 16:30:00
 	descrition 	:限定活动管理
--]]

LimitActivMgr = {Name = "LimitActivMgr"}

local My = LimitActivMgr

local Info = require("TimeLimitActiv/LimitActivInfo")

function My:Init()
    Info:Init()
    --红点列表（1.仙途之路 2.材料掉落 3.仙途商店）
    self.actionDic = {}
    self.eBuy = Event()
    self.eUpAction = Event()
    self:SetLnsr(ProtoLsnr.Add)
    PropMgr.eUpdate:Add(self.RespUpdate, self)
end

--设置监听
function My:SetLnsr(func)
    func(26420, self.RespInfo, self)
    func(26422, self.RespBuy, self)
end

--响应仙途商店信息
function My:RespInfo(msg)
    -- iTrace.Error("msg = "..tostring(msg))
    for i,v in ipairs(msg.buy_list) do
        Info:SetBuyList(v.id, v.val)
    end
    self:UpRedDot()
end

--请求兑换
function My:ReqBuy(id)
    local msg = ProtoPool.GetByID(26421)
    msg.id = id
    ProtoMgr.Send(msg)
end

--响应兑换
function My:RespBuy(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    end
    local id = msg.id
    Info:UpBuyCount(id)
    self.eBuy(id)
    self:UpRedDot()
end

--响应道具获得
function My:RespUpdate()
    self:UpRedDot()
end

--更新红点（外部调用）
function My:UpAction(k,v)
	local key = tostring(k)
	if type(key) ~= "string" or type(v) ~= "boolean" then
		iTrace.Error("传入的参数错误")
		return
    end
	self.actionDic[key] = v
	self:UpRedDotState()
	self.eUpAction()
end

--更新红点
function My:UpRedDotState()
	for k,v in pairs(self.actionDic) do
        local index = tonumber(k)
		self:ChangeRedDot(v, index)
    end
end

--改变红点状态
function My:ChangeRedDot(state, index)
    local actId = ActivityMgr.XTZL
    if state then
        SystemMgr:ShowActivity(actId, index)
    else
        SystemMgr:HideActivity(actId, index)
    end
end

--更新仙途商店红点
function My:UpRedDot()
    local isShow = self:IsShowAction()
    self:UpAction(3, isShow)
end

--是否显示仙途商店红点
function My:IsShowAction()
    for i,v in ipairs(LimitActivStoreCfg) do
        local id = v.buyItem
        local count = ItemTool.GetNum(id)
        local isBuy = count >= v.buyCount
        
        local num = Info:GetCount(v.id)
        local isMax = ((v.maxCount - num) <= 0)

        if isBuy and (not isMax) then return true end
    end
    return false
end

--清理缓存
function My:Clear()
    Info:Clear()
    TableTool.ClearDic(self.actionDic)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
end

return My