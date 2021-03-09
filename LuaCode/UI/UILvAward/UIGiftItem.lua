--[[
 	authors 	:Liu
 	date    	:2018-5-22 16:09:28
 	descrition 	:奖励项
--]]

UIGiftItem = Super:New{Name="UIGiftItem"}

local My = UIGiftItem

function My:Init(root, award)
    local id = award.I
    local val = award.B
    local isEff = award.N==2
    self:InitCell(root, id, val, isEff)
end

--初始化Cell
function My:InitCell(tran, id, val, isEff)
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(tran, 0.8)
    self.cell:UpData(id, val, isEff)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
end

return My