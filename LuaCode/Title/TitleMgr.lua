TitleMgr = Super:New{Name = "TitleMgr"}

local M = TitleMgr

M.Type = {
    Had = 0,
    RY = 1,
    CJ = 2,
    HD = 3,
    XL = 4
}

M.ToggleGroup={
    {id = M.Type.Had, name = "拥有称号"},
    {id = M.Type.RY, name = "荣誉称号"},
    {id = M.Type.CJ, name = "成就称号"},
    {id = M.Type.HD, name = "活动称号"},
    {id = M.Type.XL, name = "侠侣称号"}
}

function M:Init()
    self.eUpdate = Event()
    self:InitData()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:InitData()
    local t= self.Type
    self.TitleInfo = {
        [t.Had] = {}, --拥有的
        [t.RY] = {}, --荣誉称号
        [t.CJ] = {}, --成就称号
        [t.HD] = {}, --活动称号
        [t.XL] = {}  --侠侣称号
    }
    self:InitTitleInfo()
end



function M:SetLsnr(func)
    func(22350, self.RespTitleInfo, self)
    func(22352, self.RespTitleUpdate, self)
    func(22354, self.RespTitleChange, self)
end

function M:RespTitleInfo(msg)
    self:AddTitles(msg.titles)
    self:SetCurTitle(msg.cur_title)  
    self:Reposition()
    self.eUpdate()
end

function M:RespTitleUpdate(msg)
    self:AddTitles(msg.update_titles)
    self:DelTitles(msg.del_titles)
    self:Reposition()
    self.eUpdate()
end

function M:RespTitleChange(msg)
    if msg.err_code == 0 then
        self:SetCurTitle(msg.cur_title)
        self:Reposition()
        self.eUpdate()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

function M:ReqTitleChange(id)
    local msg = ProtoPool.GetByID(22353)
    msg.title_id = id
    ProtoMgr.Send(msg)
end

--==============================--


--初始化称号数据
function M:InitTitleInfo()
    local list = self.TitleInfo
    for k,v in pairs(TitleCfg) do
        local temp = {}
        temp.isUse = 0
        temp.have = -1 --  -1:未拥有， 0：拥有   >0 :限时
        temp.cfg = v
        table.insert(list[v.type], temp)
    end
end

--根据id获取对应的称号数据
function M:GetTitleInfo(id)
    local cfg = TitleCfg[tostring(id)]
    if not cfg then return end

    local list = self.TitleInfo[cfg.type]
    if list then
        local len = #list
        for i=1,len do
            if list[i].cfg.id == id then
                return list[i]
            end
        end
    end
    iTrace.sLog("XGY", string.format("self.TitleInfo[type]不存在id：%s的称号", id))
end

--获取该对象在list中的索引
function M:IndexOf(list, id)
    if not list or not id then return end
    local len = #list
    for i=1,len do
        if list[i].cfg.id == id then
            return i
        end
    end
end

--设置佩戴的称号
function M:SetCurTitle(id)
    local list = self.TitleInfo[self.Type.Had]
    local len = #list
    for i=1,len do
        list[i].isUse = id == list[i].cfg.id and 1 or 0
    end
end

--新增激活的称号
function M:AddTitles(data)
    local len = #data
    if len == 0 then return end
    local list = self.TitleInfo
    for i=1,len do
        local title = self:GetTitleInfo(data[i].id)
        if title then
            title.have = data[i].val 
            local temp = list[self.Type.Had]
            local index = self:IndexOf(temp, data[i].id)
            if index then
                temp[index] = title 
            else
                table.insert(temp, title)
            end
        end   
    end
end

--删除过期的称号
function M:DelTitles(data)
    local len = #data
    if len == 0 then return end
    local list = self.TitleInfo
    for i=1, len do 
        local title = self:GetTitleInfo(data[i])
        if title then
            title.isUse = 0
            title.have = -1
            local temp = list[self.Type.Had]
            local index = self:IndexOf(temp, data[i])
            if index then
                table.remove(temp, index)
            end
        end
    end
end

--刷新位置
function M:Reposition()
    local list = self.TitleInfo
    local t = self.Type
    for k,v in pairs(t) do
        table.sort(list[v], function(a,b) return self:Sort(a,b) end)
    end
end

--排序
function M:Sort(a, b)
    if a.isUse == 1 then
        return true
    end
    
    if b.isUse == 1 then
        return false
    end

    if a.have > -1 and b.have > -1 then
        return a.cfg.id < b.cfg.id
    elseif a.have > -1 then
        return true
    elseif b.have > -1 then
        return false
    else
        return a.cfg.id < b.cfg.id
    end
end

function M:Clear()
    self:InitData()
end

return M