--[[
 	authors 	:Liu
 	date    	:2018-7-10 12:00:00
 	descrition 	:装备寻宝背包
--]]

UIEquipTreasBag = Super:New{Name="UIEquipTreasBag"}

local My = UIEquipTreasBag

function My:Init(root)
    local des = self.Name
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.go = root.gameObject
    self.isOpen = false
    self.bagTran = Find(root, "bg3", des)

    SetB(root, "CloseBtn", des, self.Hide, self)

    self:InitBag()
end

--初始化寻宝背包
function My:InitBag()
    self.bag = ObjPool.Get(CellUpdate)
    self.bag:Init(self.bagTran)
    self.bag:InitData(3)
end

--显示
function My:Show()
    self:SetState(true, true)
    -- self:UpEffItem(false)
end

--隐藏
function My:Hide()
    self:SetState(false, false)
    local it = UITreasure
    if it.equip then
        it.equip:UpRedDot()
        it.equip:UpModelShow(true)
    end
    if it.top then
        it.top:UpRedDot()
        it.top:UpModelShow(true)
    end
    -- self:UpEffItem(true)
end

-- --修复特效遮挡
-- function My:UpEffItem(state)
--     local list = UITreasure.equip.roule.itList
--     if list == nil or #list < 1 then return end
--     for i,v in ipairs(list) do
--         v:UpShow(state)
--     end
-- end

--设置面板状态
function My:SetState(state1, state2)
    self.go:SetActive(state1)
    self.isOpen = state2
end

--清理缓存
function My:Clear()
    self.isOpen = false
    TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    ObjPool.Add(self.bag)
    self.bag = nil
end

return My