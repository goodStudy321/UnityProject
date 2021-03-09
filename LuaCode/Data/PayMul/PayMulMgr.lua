PayMulMgr = {Name = "PayMulMgr"}

local My = PayMulMgr

--红点列表(1.首充倍送)
My.actionDic = {}
My.eUpAction = Event()

function My:Init()
    self:SetLnsr(ProtoLsnr.Add)
end

--设置监听
function My:SetLnsr(func)
    -- func(20384,self.RespLvAward, self)
end

--更新红点（外部调用）
function My:UpAction(k,v)
	local key = tostring(k)
	if type(key) ~= "string" or type(v) ~= "boolean" then
		iTrace.Error("传入的参数错误")
		return
    end
	My.actionDic[key] = v
	self:UpRedDotState()
	My.eUpAction()
end

--更新红点
function My:UpRedDotState()
	for k,v in pairs(My.actionDic) do
        local index = tonumber(k)
		self:ChangeRedDot(v, index)
    end
end

--改变红点状态
function My:ChangeRedDot(state, index)
    local actId = ActivityMgr.SCBS
    if state then
        SystemMgr:ShowActivity(actId, index)
    else
        SystemMgr:HideActivity(actId, index)
    end
end

--清理缓存
function My:Clear()
    TableTool.ClearDic(My.actionDic)
end

--释放资源
function My:Dispose()
    self:SetLnsr(ProtoLsnr.Remove)
end

return My