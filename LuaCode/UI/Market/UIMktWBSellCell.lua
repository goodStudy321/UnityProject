UIMktWBSellCell = Super:New{Name = "UIMktWBSellCell"}

local M = UIMktWBSellCell


function M:Init(gameObj)
    self.obj = gameObj
    self.objTrans = self.obj.transform

    local C = ComTool.Get
    local T = TransTool.FindChild
end

function M:InitCfg(tb,selCB)
    if tb == nil then
        self.isSel = nil
        self.selCallBack = nil
        return
    end

    self.data = tb
    self.selCallBack = selCB

    if not self.cellCont then
        self.cellCont = ObjPool.Get(UIItemCell)
        self.cellCont:InitLoadPool(self.objTrans)
        UITool.SetLsnrSelf(self.cellCont.trans.gameObject,self.ClickSelf,self,self.Name, false)
    end
    
    self.cellCont:TipData(self.data,self.data.num)
end

function M:Click()
    self.cellCont:Select(true)
    
end

function M:EquipCb(name)
    local ui =UIMgr.Get(name)
    if ui then
        ui:UpData(self.data)
    end
end

function M:PropCb(name)
    local ui =UIMgr.Get(name)
    if ui then
        ui:UpData(self.data)
    end
end

function M:ClickSelf()
    local ufx = ItemData[tostring(self.data.type_id)].uFx or 0
    if  ufx == 1 then
        UIMgr.Open(EquipTip.Name,self.EquipCb,self)
    else
        UIMgr.Open(PropTip.Name,self.PropCb,self)
    end
    if self.selCallBack ~= nil then
        self.selCallBack()
    end
end

function M:Select(active)
    self.cellCont:Select(active)
end

function M:Show(isShow)
    self.obj:SetActive(isShow)
end

function M:Dispose()
    if self.cellCont ~= nil then
		self.cellCont:DestroyGo()
		ObjPool.Add(self.cellCont)
        self.cellCont = nil
    end
    self.isSel = nil
    self.selCallBack = nil
end

return M