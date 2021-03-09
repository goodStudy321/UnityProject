--[[
 	authors 	:Liu
 	date    	:2019-4-13 19:02:00
 	descrition 	:引导跳转界面
--]]

UIGuideJumpMenu = Super:New{Name="UIGuideJumpMenu"}

local My = UIGuideJumpMenu

require("UI/UILiveness/UIGuideJumpMenuIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str = "Scroll View/Grid"

    self.itList = {}

    self.grid = CG(UIGrid, root, str)
    self.item = FindC(root, str.."/item", des)
    
    self:InitItem()
end

--更新配置
function My:UpCfg(type)
    self:HideItem()
    local list = self:GetCfgFromType(type)
    if #list < 1 then return end
    for i,v in ipairs(self.itList) do
        if i > #list then return end
        v:UpName(list[i].id)
        v:UpData(list[i])
        v:UpShow(true)
    end
    self.grid:Reposition()
end

--初始化跳转项
function My:InitItem()
    local Add = TransTool.AddChild
    local len = self:GetMaxLen()
    for i=1, len do
        local item = Instantiate(self.item)
        local tran = item.transform
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(UIGuideJumpMenuIt)
        it:Init(tran)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
end

--根据类型获取配置
function My:GetCfgFromType(type)
    local list = {}
    for i,v in ipairs(GuideJumpCfg) do
        if v.type == type then
            table.insert(list, v)
        end
    end
    return list
end

--获取最大长度
function My:GetMaxLen()
    local list = {}
    local dic = {}
    local len = 0
    for i,v in ipairs(GuideJumpCfg) do
        dic[tostring(v.type)] = true
    end
    for k,v in pairs(dic) do
        table.insert(list, tonumber(k))
    end
    for i,v in ipairs(list) do
        local temp = 0
        for i1,v1 in ipairs(GuideJumpCfg) do
            if v == v1.type then
                temp = temp + 1
            end
        end
        len = (len>temp) and len or temp
    end
    return len
end

--隐藏跳转项
function My:HideItem()
    for i,v in ipairs(self.itList) do
        v:UpShow(false)
    end
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    ListTool.ClearToPool(self.itList)
end

return My