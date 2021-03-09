--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:奖励道具项
--]]

UIRankAwardItem = Super:New{Name = "UIRankAwardItem"}

local My = UIRankAwardItem

function My:Init(root)
    self.root = root
    self.go = root.gameObject
end

--更新Cell
function My:UpCell(cfg)
    if not self.cell then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.root, 0.7)
    end
    self.cell:UpData(cfg.I, cfg.B, cfg.N==2)
end

--更新绝版标识图片
function My:UpSpr()
    if self.cell then
        self.cell:FirstPayLeft("sc_ jb")
    end
end

--清理缓存
function My:Clear()

end
    
--释放资源
function My:Dispose()
    self:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return My