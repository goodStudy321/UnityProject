ActPreviewMgr = Super:New{Name = "ActPreviewMgr"}

local M = ActPreviewMgr

function M:Init()
    self.eUpdatePreview = Event()
    self.eChgUI = Event()
    self.eChgBtn = Event()
    self.eShow = Event()
    self.eShowData = Event()
    self:InitData()
    self:SetLsnr(ProtoLsnr.Add)
    EventMgr.Add("OnChangeLv",EventHandler(self.SetShowInfo,self))
end

function M:SetLsnr(func)
    func(22430, self.RespFunctionList, self)
    func(22432, self.ResAward, self)
end

function M:InitData()
    self.dataList = {}
    self.allList = {}
    self.curData = nil
    self.getList = {}
    self.openList = {}
    self:InitDataList()
end

function M:InitDataList()
    local dataList = self.dataList
    local allList = self.allList
    for k,v in pairs(SystemOpenTemp) do
        if v.preview and v.preview == 1 then
            local temp = {}
            if v.trigType == 1 then          
                temp.level = v.trigParam
            elseif v.trigType == 2 then
                local info = MissionTemp[tostring(v.trigParam)]
                if not info then break end
                temp.level = info.lv
            else
                iTrace.sLog("XGY","系统开放表--触发方式--配置错误")
                return
            end
            temp.id = v.id
            temp.des = v.des
            temp.texture = v.icon
            temp.previewDes = v.preViewDes
            temp.trigType = v.trigType
            if v.award then
                temp.award = v.award  
            end
            --temp.lvLimit = v.lvLimit
            temp.jump = v.jump
            table.insert(dataList, temp)
            table.insert(allList, temp)
        end
    end
    table.sort(dataList, function(a,b) return a.level < b.level end)
    table.sort(allList, function(a,b) return a.level < b.level end)
    self:SetShowInfo()
end


function M:GetCurData()
    return self.curData 
end

function M:SetShowInfo()
    local list = self.allList
    local modData = {}
    local funcData = {}
    for i,v in ipairs(list) do
        -- if not v.lvLimit then 
        --     return 
        -- end
        if #v.texture > 1 then
            table.insert(modData, v)
        else
            table.insert(funcData, v)
        end
        self.modData = modData
        self.funcData = funcData
    end
    
end

function M:GetModList()
    local list = self.modData
    local lv = User.MapData.Level
    -- for i=#list,1,-1 do
    --     if list[i].lvLimit > lv then
    --         table.remove( list, i)
    --     end
    -- end
    return list
end

function M:GetfuncList()
    local list = self.funcData
    -- local lv = User.MapData.Level
    -- for i=#list,1,-1 do
    --     if list[i].lvLimit > lv then
    --         table.remove( list, i)
    --     end
    -- end
    return list
end

function M:SetCurData()
    local list = self.dataList
    if #list > 0 then
        if not self.curData then
            self.curData = list[1]
        elseif self.curData.id ~= list[1].id then
            self.curData = list[1]
            self.eUpdatePreview()
            --self.eShowData()
        end
    else
        self.curData = nil
        self.eUpdatePreview()
        --self.eShowData()
    end 
end

function M:UpdateDataList(id)
    local list = self.dataList
    local len = #list
    for i=1,len do
        if list[i].id == id then
            table.remove(list, i)
            return
        end
    end
end

function M:GetAwardList()
    local temp = {}
    for i,v in ipairs(self.getList) do
        local tp = {}
        tp.id = v
        local data = SystemOpenTemp[tostring(v)]
        if data.trigType == 2 then
            tp.lv = MissionTemp[tostring(data.trigParam)].lv
        else
            tp.lv = data.trigParam
        end
        temp[# temp + 1] = tp
    end
    table.sort( temp, function ( a,b )
        return a.lv<b.lv
    end )
    return temp
end

function M:GetOpenList()
    local list = self.openList
    local len = #list
    local lv = User.MapData.Level
    local temp = {}
    for i=#list,1,-1 do
        if SystemOpenTemp[tostring(list[i])] then
            local data = SystemOpenTemp[tostring(list[i])]
            if data.preview and data.preview == 1 and #data.icon == 1 then
                if OpenMgr:IsOpen(tostring(list[i])) == true and data.award then
                    table.insert(temp,list[i])
                end
            end
        end
    end
    -- for i=#temp,1,-1 do
    --     local data = SystemOpenTemp[tostring(list[i])]
    --     if not data then break end
    --     if data.lvLimit and  lv < data.lvLimit then
    --        table.remove( temp, i )
    --     end
    -- end

    local temp1 = {}
    for i,v in ipairs(temp) do
        local tp = {}
        tp.id = v
        local data = SystemOpenTemp[tostring(v)]
        if data.trigType == 2 then
            tp.lv = MissionTemp[tostring(data.trigParam)].lv
        else
            tp.lv = data.trigParam
        end
        temp1[# temp1 + 1] = tp
    end
    table.sort( temp1, function ( a,b )
        return a.lv<b.lv
    end )
    return temp1
end

function M:IsOpen()
    local list = self:GetOpenList()
    self.allopenList = temp
    if self.getList == nil then
        return false;
    end
    local len1 = #list
    local len2 = #self.getList
    if len1 == len2 then
        return false
    else
        return true
    end
end

--==============================--

-- type 0：上线推送 1：更新推送
function M:RespFunctionList(msg)
    local type = msg.op_type
    local list = msg.id_list
    local getList = msg.reward_list
    self.openList = {}
    for i,v in ipairs(list) do
        table.insert( self.openList, v )
    end
    if type == 0 then
        self.getList = {}
        for i,v in ipairs(getList) do
            table.insert( self.getList, v )
        end
    end
    local len = #list
    for i=1,len do
        self:UpdateDataList(list[i])
        User.instance:AddSystemOpen(list[i]);
    end
    self:SetCurData()
    self:SetShowInfo()
    self.eShow()
end

function M:ResAward(msg)
    if msg.err_code == 0 then
        local id = msg.id
        table.insert( self.getList, id)
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
        return
    end
    self.eChgBtn()
    self.eShow()
    self.eShowData()
end

function M:ReqAward(id)
    local msg = ProtoPool.GetByID(22431)
    msg.id = id
    ProtoMgr.Send(msg)
end

function M:Clear()
    self:InitData()
    self:ClearUIModel()
end

function M:ClearUIModel()
    local it = UIActPreview
    if not it then return end
    it:Clear()
end

return M