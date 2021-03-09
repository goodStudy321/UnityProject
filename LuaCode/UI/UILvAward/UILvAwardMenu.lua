--[[
 	authors 	:Liu
 	date    	:2019-3-26 19:20:00
 	descrition 	:冲级豪礼界面
--]]

UILvAwardMenu = Super:New{Name="UILvAwardMenu"}

local My = UILvAwardMenu

require("UI/UILvAward/UILvAwardItem")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local str = "Scroll View/Grid"
    
    self.itDic = {}
    self.actionList = {}
    self.go = root.gameObject

    self.grid = CG(UIGrid, root, str)
    self.gridTran = Find(root, str, des)
    self.lvAwardItem = FindC(root, str.."/GiftItem", des)
    self.svTran = Find(root, "Scroll View", des)
    self.yPos = self.svTran.localPosition.y
    self.firstCount = 4

    self:InitItem(true)
    self:UpItemState()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = LvAwardMgr
    mgr.eLvAward[func](mgr.eLvAward, self.RespLvAward, self)
    mgr.eWordLvAward[func](mgr.eWordLvAward, self.RespWordLvAward, self)
    mgr.eUpLvAwardInfo[func](mgr.eUpLvAwardInfo, self.RespUpLvAwardInfo, self)
end

--响应获取等级奖励
function My:RespLvAward(key)
    if self.svTran then
        self:InitItem(false)
        self.svTran = nil
    end
    self.itDic[key]:YetGet()
    self:UpItemState()
    self.grid:Reposition()
end

--响应获取限制奖励
function My:RespWordLvAward(key)
    self.itDic[key]:UpCountLab()
end

--更新等级奖励信息
function My:RespUpLvAwardInfo()
    self:UpItemState()
end

--更新
function My:Update()
    if self.svTran and self.svTran.localPosition.y ~= self.yPos then
        self:InitItem(false)
        self:UpItemState()
        self.grid:Reposition()
        self.svTran = nil
    end
end

--再次初始化
function My:ReInitItem()
    self:InitItem(false)
    self:UpItemState()
    self.grid:Reposition()
    self.svTran = nil
end

--初始化等级奖励项
function My:InitItem(isFirst)
    local Add = TransTool.AddChild
    local parent = self.gridTran
    local list = (isFirst==true) and self:GetInitItem() or LvAwardCfg
    for i,v in ipairs(list) do
        local key = tostring(v.id)
        if self.itDic[key] == nil then
            local item = Instantiate(self.lvAwardItem)
            item:SetActive(true)
            local num = 100 + i
            item.name = num
            local tran = item.transform
            Add(parent, tran)
            local it = ObjPool.Get(UILvAwardItem)
            it:Init(tran, v)
            self.itDic[key] = it
        end
    end
    self.lvAwardItem:SetActive(false)
end

--更新等级奖励项状态
function My:UpItemState()
    local dic = self.itDic
    local info = LvAwardInfo
    for k,v in pairs(dic) do
        local cfg = v.cfg
        if User.MapData.Level >= cfg.id then
            if info.selfDic[k] then
                v:YetGet()
            else
                local count = info:GetWordAward(cfg)
                if count == 0 and cfg.count ~= 0 then
                    v:NoGet()
                else
                    v:MayGet()
                end
            end
        else
            v:NoGet()
        end
    end
end

--获取奖励项分类列表
function My:GetStateList()
    local list1 = {}--可领取
    local list2 = {}--未领取
    local list3 = {}--已领取
    local info = LvAwardInfo
    for i,v in ipairs(LvAwardCfg) do
        if User.MapData.Level >= v.id then
            if info.selfDic[tostring(v.id)] then
                table.insert(list3, v)
            else
                local count = info:GetWordAward(v)
                if count == 0 and v.count ~= 0 then
                    table.insert(list2, v)
                else
                    table.insert(list1, v)
                end
            end
        else
            table.insert(list2, v)
        end
    end
    return list1, list2, list3
end

--获取需要初始化的奖励项
function My:GetInitItem()
    local temp = {}
    local list1, list2, list3 = self:GetStateList()
    temp = self:SetList(temp, list1)
    if #temp >= self.firstCount then return temp end
    temp = self:SetList(temp, list2)
    if #temp >= self.firstCount then return temp end
    temp = self:SetList(temp, list3)
    return temp
end

--设置列表
function My:SetList(list, list1)
    for i,v in ipairs(list1) do
        if #list >= self.firstCount then
            return list
        else
            table.insert(list, v)
        end
    end
    return list
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.itDic)
end

return My