--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面Togs下的Grid
--]]

UISuccessTogsGrid = Super:New{Name = "UISuccessTogsGrid"}

local My = UISuccessTogsGrid

require("UI/UISuccess/UISuccessTogsGridIt")

function My:Init(root, cfg)
    local des, FindC = self.Name, TransTool.FindChild
    local item = FindC(root, "item", des)

    self.grid = ComTool.GetSelf(UITable, root, des)
    self.go = root.gameObject
    self.itList = {}

    self:InitTogs(item, cfg)
end

--初始化所有Tog
function My:InitTogs(item, cfg)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(cfg.cType) do
        local go = Instantiate(item)
        local tran = go.transform
        go.name = "tog"..i
        Add(parent, tran)
        local it = ObjPool.Get(UISuccessTogsGridIt)
        it:Init(tran, v)
        it:UpLab()
        table.insert(self.itList, it)
    end
    item:SetActive(false)
end

--更新显示
function My:UpShow(state)
    if not state then return end
    for i,v in ipairs(self.itList) do
        v:SetMarkState()
    end
end

--清理缓存
function My:Clear()
    self.grid = nil
end

-- 释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My