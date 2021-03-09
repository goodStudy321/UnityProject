--[[
 	authors 	:Liu
 	date    	:2019-7-27 11:20:00
 	descrition 	:丹药属性弹窗
--]]

UIElixirProPop = Super:New{Name = "UIElixirProPop"}

local My = UIElixirProPop

require("UI/UIRole/Elixir/UIElixirProPopIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.proDic = {}
    self.itList = {}
    self.nameDic = {}
    self.valDic = {}
    self.proList1 = {}
    self.proList2 = {}

    self.go = root.gameObject

    self.grid = CG(UIGrid, root, "Scroll View/Grid")
    self.sView = CG(UIScrollView, root, "Scroll View")
    self.title = CG(UILabel, root, "bgs/title")
    self.item = FindC(root, "Scroll View/Grid/item", des)
    self.item:SetActive(false)

    SetB(root, "mask", des, self.OnMask, self)
end

--更新数据
function My:UpData(type)
    if type == nil then return end
    self:HideItem()
    if type == 0 then
        self:GetProLab1()
        self:UpItem(0)
        self.title.text = "永久属性总览"
    elseif type == 1 then
        self:GetProLab2()
        self:UpItem(1)
        self.title.text = "限时属性总览"
    end
end

--获取属性项最大数量（限时）
function My:GetMaxLen()
    local len = 0
    for k,v in pairs(self.nameDic) do
        len = len + #v + 1
    end
    return len
end

--更新属性项
function My:UpItem(type)
    local Add = TransTool.AddChild
    local list = self.itList
    local gridTran = self.grid.transform
    local len = (type==0) and TableTool.GetDicCount(self.proDic) or self:GetMaxLen()
    local num = len - #list

    for i=1, num do
        local go = Instantiate(self.item)
        local tran = go.transform
        go:SetActive(true)
        Add(gridTran, tran)
        local it = ObjPool.Get(UIElixirProPopIt)
        it:Init(tran)
        table.insert(self.itList, it)
    end
    self:RefreshItem(type)
    self.sView:ResetPosition()
    self.grid:Reposition()
end

--刷新属性项
function My:RefreshItem(type)
    local len = 0
    local index = 0
    local maxLen = 0
    local dic = (type==0) and self.proDic or self.nameDic
    for k,v in pairs(dic) do
        len = len + 1
        if type == 1 then
            index = maxLen
            maxLen = maxLen + #v + 1
        end
        if type == 0 then
            local cfg = PropName[tonumber(k)]
            if cfg == nil then return end
            local it = self:UpShowItem(len, type, false)
            if it == nil then return end
            it:UpLabs(cfg.name, v, cfg.show)
        elseif type == 1 then
            local curIndex = 0
            for i1=index+1, maxLen do
                curIndex = curIndex + 1
                local isFirst = (curIndex==1)
                local sec = self.proDic[k]
                local it = self:UpShowItem(i1, type, isFirst)
                if it == nil then return end
                if isFirst == true then
                    it:UpLimitLabs("", 0, 0, sec, k, isFirst)
                else
                    local num = curIndex-1
                    local temp = self.valDic[k]
                    local name = v[num]
                    local val = temp[num] 
                    local cfg = PropName[tonumber(name)]
                    if cfg == nil then return end
                    it:UpLimitLabs(cfg.name, val, cfg.show, sec, k, isFirst)
                end
            end
        end
    end
end

--更新显示属性项
function My:UpShowItem(len, type, isFirst)
    local isShow = (type==0) and ((len%2)==0) or isFirst
    local it = self.itList[len]
    if it == nil then return end
    it:UpShow(true)
    it:UpSprShow(isShow)
    return it
end

--隐藏排行项
function My:HideItem()
    for i,v in ipairs(self.itList) do
        v:UpShow(false)
    end
end

--获取永久丹药总览文本
function My:GetProLab1()
    TableTool.ClearDic(self.proDic)
    for k,v in pairs(UIElixir.itDic) do
        if v.cfg.type == 0 then
            local list = ElixirMgr:GetProList(k)
            for i1,v1 in ipairs(list) do
                local strList = StrTool.Split(v1, ",")
                local dic = self.proDic[strList[1]]
                if dic then
                    self.proDic[strList[1]] = dic + strList[2]
                else
                    self.proDic[strList[1]] = tonumber(strList[2])
                end
            end
        end
    end
end

--获取限时丹药总览文本
function My:GetProLab2()
    for k,v in pairs(UIElixir.itDic) do
        local cfg = v.cfg
        local type = cfg.type
        local id = cfg.id
        if type == 1 then
            local key = tostring(id)
            local sec = ElixirMgr:GetElixirTime(id)
            if sec > 0 then
                local list = ElixirMgr:GetProList(k)
                ListTool.Clear(self.proList1)
                ListTool.Clear(self.proList2)
                for i1,v1 in ipairs(list) do
                    local strList = StrTool.Split(v1, ",")
                    table.insert(self.proList1, strList[1])
                    table.insert(self.proList2, strList[2])
                end
                self.proDic[key] = sec
                self:UpProsDic(self.nameDic, self.proList1, key)
                self:UpProsDic(self.valDic, self.proList2, key)
            end
        end
    end
end

--更新属性字典
function My:UpProsDic(dic, proList, key)
    dic[key] = {}
    for i,v in ipairs(proList) do
        table.insert(dic[key], v)
    end
end

--点击遮罩
function My:OnMask()
    self:UpShow(false, nil)
end

--更新显示
function My:UpShow(state, type)
    self.go:SetActive(state)
    if state then self:UpData(type) end
end

--清理缓存
function My:Clear()
    TableTool.ClearDic(self.proDic)
    TableTool.ClearDic(self.nameDic)
    TableTool.ClearDic(self.valDic)
    ListTool.ClearToPool(self.itList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My