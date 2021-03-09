--[[
 	authors 	:Liu
 	date    	:2019-7-25 11:30:00
 	descrition 	:丹药系统管理
--]]

ElixirMgr = {Name = "ElixirMgr"}

local My = ElixirMgr

function My:Init()
    self.ElixirDic = {}
    self.strList = {}
    self.maxProCount = 5
    self.isShow = false

    self.eUse = Event()
    self.eOverdue = Event()
    self.eAction = Event()

    self:SetLnsr(ProtoLsnr.Add)
    RobberyMgr.eUpInfo:Add(self.UpAction, self)
    PropMgr.eRemove:Add(self.UpAction, self)
    PropMgr.eUpdate:Add(self.UpAction, self)
end

--设置监听
function My:SetLnsr(func)
    func(26452, self.RespInfo, self)
    func(26454, self.RespUse, self)
    func(26456, self.RespOverdue, self)
end

--请求丹药信息
function My:ReqInfo()
    local msg = ProtoPool.GetByID(26451)
    ProtoMgr.Send(msg)
end

--响应丹药信息
function My:RespInfo(msg)
    -- iTrace.Error("msg = "..tostring(msg))
    TableTool.ClearDic(self.ElixirDic)
    for i,v in ipairs(msg.medicine) do
        self:SetElixirData(v.goods_id, v.type, v.num, v.stop_time)
    end
    self:UpAction()
end

--请求丹药使用
function My:ReqUse(id, count)
    local msg = ProtoPool.GetByID(26453)
    msg.type_id = id
    msg.num = count
    ProtoMgr.Send(msg)
end

--响应丹药使用
function My:RespUse(msg)
    -- iTrace.Error("msg1 = "..tostring(msg))
    local err = msg.err_code
	if (err>0) then
        UITip.Log(ErrorCodeMgr.GetError(err))
		return
    end
    for i,v in ipairs(msg.medicine) do
        self:SetElixirData(v.goods_id, v.type, v.num, v.stop_time)
        self.eUse(v.goods_id)
    end
    self:UpAction()
end

--响应丹药过期
function My:RespOverdue(msg)
    -- iTrace.Error("msg2 = "..tostring(msg))
    local key = tostring(msg.type_id)
    if self.ElixirDic[key] then
        self.ElixirDic[key].endTime = 0
    end
    self.eOverdue(key)
    self:UpAction()
end

--设置丹药数据
function My:SetElixirData(id, type, count, endTime)
    for k,v in pairs(self.ElixirDic) do
        if v.id == id then
            v.type = type
            v.count = count
            v.endTime = endTime
            return
        end
    end
    local data = {}
    data.id = id
    data.type = type
    data.count = count
    data.endTime = endTime
    self.ElixirDic[tostring(id)] = data
end

--获取永久丹药总览文本列表
function My:GetProList(key)
    local str = ""
    ListTool.Clear(self.strList)
    local cfg = ElixirCfg[key]
    if cfg == nil then return end
    for i=1, self.maxProCount do
        local proList = cfg["pro"..i]
        if #proList > 0 then
            local proId = proList[1]
            local proVal = proList[2]
            if proVal == nil then break end
            local info = PropName[proId]
            local count = (cfg.type==0) and self:GetElixirCount(tonumber(key)) or 1
            local temp = (info.show==1) and (proVal/10000*100*count) or proVal*count
            str = string.format("%s,%s", proId, temp)
            table.insert(self.strList, str)
        end
    end
    return self.strList
end

--是否激活
function My:IsActive(id)
    return self.ElixirDic[tostring(id)] ~= nil
end

--获取丹药剩余时间
function My:GetElixirTime(id)
    local isActive = self:IsActive(id)
    if isActive then
        local endTime = self.ElixirDic[tostring(id)].endTime
        local sec = CustomInfo:GetLeftTime(endTime)
        return sec
    else
        return 0
    end
end

--获取丹药数量
function My:GetElixirCount(id)
    local isActive = self:IsActive(id)
    if isActive then
        local count = self.ElixirDic[tostring(id)].count
        return count
    else
        return 0
    end
end

--判断丹药使用是否达到上限
function My:IsMax(id, count, type, time, maxHour)
    local isActive = self:IsActive(id)
    if isActive==false then
        return false
    elseif type == 0 then
        return self.ElixirDic[tostring(id)].count >= count
    elseif type == 1 then
        local sec = self:GetElixirTime(id)
        local maxTime = maxHour*60*60
        local useTime = time*60
        return (sec + useTime) > maxTime
    end
end

--更新红点
function My:UpAction()
    local isOpen = OpenMgr:IsOpen(707)
    if isOpen == nil or isOpen == false then return end
    self.isShow = false
    local rCfg = RobberyMgr:GetCurCfg()
    if rCfg == nil then return end
    for k,v in pairs(ElixirCfg) do
        local isMax = ElixirMgr:IsMax(v.id, v.max, v.type, v.time, v.max)
        local cfg = ItemData[k]
        local count = ItemTool.GetNum(cfg.id)
        if count == nil then return end
        if v.type == 0 then
            local name, val, id = ElixirMgr:GetDes2Lab(v)
            if isMax==false and rCfg.id>=id and count > 0 then
                self.isShow = true
            end
        -- elseif v.type == 1 then
        --     if isMax==false and count > 0 then
        --         self.isShow = true
        --     end
        end
    end
    local actId = ActivityMgr.DY
    if self.isShow then
        SystemMgr:ShowActivity(actId, 5)
    else
		SystemMgr:HideActivity(actId, 5)
    end
    self.eAction(self.isShow)
end

--获取境界文本
function My:GetDes2Lab(cfg)
    local list = cfg.condList[#cfg.condList]
    local key = list.k
    local val = list.v
    local rCfg = RobberyMgr:GetCurCfg()

    if rCfg == nil then return end
    for i,v in ipairs(cfg.condList) do
        if v.k > rCfg.id then
            key = v.k
            val = v.v
            break
        end
    end
    local temp = RobberyMgr:GetCurCfg(key)
    if temp == nil then return end
    return temp.floorName, val, temp.id
end

--是否显示UI红点
function My:IsShowUiAction(cfg, count)
    local isMax = self:IsMax(cfg.id, cfg.max, cfg.type, cfg.time, cfg.max)
    local isShow = false
    if cfg.type == 0 then
        local rCfg = RobberyMgr:GetCurCfg()
        if rCfg == nil then return false end
        local name, val, id = ElixirMgr:GetDes2Lab(cfg)
        if isMax==false and rCfg.id>=id and count > 0 then
            isShow = true
        end
    -- else
    --     isShow = isMax==false and count>0
    end
    return isShow
end

--清理缓存
function My:Clear()
    TableTool.ClearDic(self.ElixirDic)
    ListTool.Clear(self.strList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr(ProtoLsnr.Remove)
    TableTool.ClearFieldsByName(self,"Event")
    RobberyMgr.eUpInfo:Remove(self.RespUpInfo, self)
    PropMgr.eRemove:Remove(self.RespCellRemove, self)
end

return My