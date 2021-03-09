AwardCell = Super:New{Name = "AwardCell"}

local M = AwardCell

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrSelf

function M:Init(go)
    self.go = go
    self.trans = go.transform
end

function M:InitItem(tb,type)
    self.data = tb
    self.type = type

    if not self.cell then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.trans,0.8)
        US(self.cell.trans.gameObject,self.ClickSelf,self,self.Name, false)
    end
    self:HideCell(true)
    local isEffect = self.data.isEffect
    local num = self.data.num or 1
    self.cell:UpData(self.data.type_id,num,isEffect~=0)
    local value = self.data.state
    if type == 1 then
        self.cell:SetGray(false,false)
    else
        self.cell:SetGray(not value,false)
    end
end

function M:HideCell(value)
    if self.cell then
        self.cell:SetActive(value)
    end
end

function M:ClickSelf()
    TreaFeverMgr:SetCurChoseCell(self.data)
    local ufx = ItemData[tostring(self.data.type_id)].uFx or 0
    if  ufx == 1 then
        UIMgr.Open(EquipTip.Name,self.TipCb,self)
    else
        PropTip.pos=self.cell.trans.position
        UIMgr.Open(PropTip.Name,self.TipCb,self)
    end
    -- if self.type == 1 then
    --     TreaFeverMgr:SetOtherAward(self.data)
    -- else
    --     TreaFeverMgr:SetChoseAward(self.data)
    -- end
end

function M:TipCb(name)
    local ui =UIMgr.Get(name)
    local state = TreaFeverMgr:GetLayerStatus()
    local curLayer = TreaFeverMgr:GetCurLayer()
    state = state[curLayer]
    
    if ui then
        local btnList = {}
        if not state then
            if self.type == 1 then
                btnList = {"EseChoose"}
            else
                btnList = {"Choose"}
            end
        end
        ui:UpData(self.data)
        ui:ShowBtn(btnList)
    end
end

function M:Show(value)
    self.go:SetActive(value)
end

function M:Dispose()
    if self.cell then
        self.cell:SetGray(false,false)
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
        self.cell = nil
    end
end

return M