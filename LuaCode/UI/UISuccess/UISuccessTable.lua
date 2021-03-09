--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面Table
--]]

UISuccessTable = Super:New{Name = "UISuccessTable"}

local My = UISuccessTable

require("UI/UISuccess/UISuccessTogs")

function My:Init(root)
    local des, FindC = self.Name, TransTool.FindChild
    local item = FindC(root, "item", des)

    self.table = ComTool.GetSelf(UITable, root, des)
    self.itList = {}

    self:InitTogs(item)
end

--初始化所有Tog
function My:InitTogs(item)
    local Add = TransTool.AddChild
    local parent = item.transform.parent
    for i,v in ipairs(SuccessTypeCfg) do
        local go = Instantiate(item)
        local tran = go.transform
        go.name = "tog"..i
        Add(parent, tran)
        local it = ObjPool.Get(UISuccessTogs)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    item:SetActive(false)
    self:UpTogsAction()
end

--更新Tog红点
function My:UpTogsAction()
    local list = SuccessMgr:CheckAction()
    for i,v in ipairs(self.itList) do
        v:UpAction(list)
    end
end

--清理缓存
function My:Clear()
    
end

-- 释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
end

return My