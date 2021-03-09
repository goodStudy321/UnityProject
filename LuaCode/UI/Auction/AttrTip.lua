--[[
关注提示面板
--]]
AttrTip = UIBase:New{Name = "AttrTip"}
local M = AttrTip

local T = TransTool.FindChild
local C = ComTool.Get
local US = UITool.SetLsnrClick

function M:InitCustom()
	
    self.C =T(self.root,"C").transform
    
    self.cell = ObjPool.Get(UIItemCell)
    self.cellRoot = T(self.C,"cell").transform
    self.cell:InitLoadPool(self.cellRoot)
    
    self.NameLab = C(UILabel, self.C, "NameLab", self.Name, false)
    -- self.btnLab=C(UILabel,self.C,"Button/Label",self.Name,false)
    
    US(self.C,"CloseBtn",self.Name,self.Close,self)
	US(self.C,"Button",self.Name,self.OnClickBtn,self)
end

function M:OpenCustom()
    self:ShowData()
end

--持续显示 ，不受配置tOn == 1 影响
function M:ConDisplay()
	do return true end
end

function M:SetEvent(fn)
    --SceneMgr.eChangeEndEvent[fn](SceneMgr.eChangeEndEvent,self.UpSprite,self)
end

function M:UpSprite()

end

function M:ShowData()
    local data = AuctionMgr:GetAttrData()
    self.cell:UpData(data.type_id)
    self.NameLab.text = data.name
end

function M:OnClickBtn()
    UIMgr.Open(UIAuction.Name)
    self:Close()
end


function M:Clear()
	if self.cell ~= nil then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return M