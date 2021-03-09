--[[
 	authors 	:Liu
 	date    	:2018-7-4 17:00:00
 	descrition 	:装备寻宝商城项
--]]

UIEquipTreasShopIt = Super:New{Name="UIEquipTreasShopIt"}

local My = UIEquipTreasShopIt

function My:Init(root, cfg)
    local des, CG = self.Name, ComTool.Get
    local nameLab = CG(UILabel, root, "nameLab")
    local scoreLab = CG(UILabel, root, "scoreLab/lab")
    local itemTran = TransTool.Find(root, "item", des)
    UITool.SetBtnClick(root, "btn", des, self.OnClick, self)
    self.cfg = cfg
    self:InitSelf(nameLab, scoreLab, itemTran)
end

--初始化自身
function My:InitSelf(lab1, lab2, parent)
    local cfg = self.cfg
    if cfg.PropId == nil then iTrace.Log("该道具配置不存在") return end
    lab1.text = cfg.name
    lab2.text = cfg.curPrice
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(parent, 0.8)
    self.cell:UpData(cfg.PropId)
end

--点击兑换
function My:OnClick()
    StoreMgr.QuickBuy(self.cfg.id, 1)
end

--清理缓存
function My:Clear()
    self.cfg = nil
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
end

return My