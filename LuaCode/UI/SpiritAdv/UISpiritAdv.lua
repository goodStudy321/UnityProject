UISpiritAdv = UIBase:New{Name = "UISpiritAdv"}

require("UI/SpiritAdv/SpiritAdvInfo")

local My = UISpiritAdv

function My:InitCustom(go)
    local root = self.root
    local name = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local TFC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.advItemRoot = TF(root,"need/item")
    self.advPropNum = CG(UILabel,root,"need/num",name)

    self.curTip = ObjPool.Get(SpiritAdvInfo)
    self.curTip:Init(TFC(root, "cur"))

    self.nextTip = ObjPool.Get(SpiritAdvInfo)
    self.nextTip:Init(TFC(root, "next"))

    self.btnClose = TFC(root, "closeBtn")
    self.advBtn = TFC(root,"Button")
    S(self.advBtn, self.OnAdvBtn, self)
    S(self.btnClose, self.CloseBtn, self)

    self:SetEvent("Add")
end

function My:SetEvent(fn)
	SpiritGMgr.eUpdateAdvInfo[fn](SpiritGMgr.eUpdateAdvInfo, self.RefreshAdv, self)
end

function My:CloseBtn()
    JumpMgr.eOpenJump()
    self:Close()
end

function My:RefreshAdv()
    self:CloseBtn()
end

function My:OnAdvBtn()
    local propInfo = self.conPropInfo
    local id = propInfo.id
    local cosNum = propInfo.value
    local propNum = PropMgr.TypeIdByNum(id)
    if propNum < cosNum then
        UITip.Error("道具数量不足")
        UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
		return 
    end
    local info = self.curData
    local id = info.id
    SpiritGMgr:ReqSpiritEquipAdv(id)
end

--获取途径界面回调
function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(192,-165,0))
    ui:CreateCell("商城", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    if name == "商城" then
        SpiritGMgr:SetAdvData(self.curData)
        JumpMgr:InitJump(UISpiritAdv.Name)
		StoreMgr.OpenStoreId(self.conPropInfo.id)
	end
end

function My:UpdateData()
    self:UpdateTip()
end

function My:UpdateTip()
    self.curTip:Open(self.curData,1)
    self.nextTip:Open(self.curData,2)
    self:UpdateAdvCell()
end

function My:Show(curData)
    self.curData = curData
    UIMgr.Open(self.Name, self.OpenCb, self)
end

function My:OpenCb()
    self:UpdateData()
end

--显示消耗道具
function My:UpdateAdvCell()
    local equipData = self:GetEquipCurCfg()
    local propInfo = equipData.consume[1]
    self.conPropInfo = propInfo
    local id = propInfo.id
    local cosNum = propInfo.value
    local propNum = PropMgr.TypeIdByNum(id)
    if not self.advCell then
        self.advCell = ObjPool.Get(Cell)
        self.advCell:InitLoadPool(self.advItemRoot.transform,0.8)
        UITool.SetLsnrSelf(self.advCell.trans, self.OnClick, self, des, false)
    end
    self.advCell:UpData(id,propNum)
    self:ShowPropNum()
end

function My:OnClick()
    UIMgr.Open(PropTip.Name, self.ShowTip, self)
end

function My:ShowTip(name)
    local ui = UIMgr.Get(name)
    local id = self.conPropInfo.id
    ui:UpData(tostring(id))
  end

--刷新道具数量
function My:UpAdvCellNum()
    local propId = self.conPropInfo.id
    local propNum = PropMgr.TypeIdByNum(propId)
    self.itemPropObj:UpLab(propNum)
    -- self:ShowPropNum()
end

function My:ShowPropNum()
    local sCfg = self.conPropInfo
    local sb = ObjPool.Get(StrBuffer)
    local itemid = tostring(sCfg.id)
    local itemData = ItemData[itemid]
    local propName = itemData.name
    local own = PropMgr.TypeIdByNum(itemid)
    local need = sCfg.value
    local propC = (own < need and "[e83030]" or "[67cc67]")
    local desLabC = "[F39800FF]"
    -- sb:Apd(desLabC):Apd("消耗:"):Apd(propName):Apd("[-]")
    -- sb:Apd(propC):Apd(own):Apd("[-]"):Apd("/"):Apd(need)
    sb:Apd(propC):Apd(own):Apd("[-]"):Apd("/"):Apd(need)
    self.advPropNum.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:GetEquipCurCfg()
    local equipId = self.curData.typeId
    equipId = tostring(equipId)
    local equipData = SpiritEquipCfg[equipId]
    return equipData
end

function My:CloseCustom()

end

function My:DisposeCustom()
    self:SetEvent("Remove")
    if self.advCell then
        self.advCell:DestroyGo() 
        ObjPool.Add(self.advCell) 
    end
    self.advCell=nil 
    self.curData = nil
    self.nextData = nil
    self.showBtn = nil
    self.compare = nil
    ObjPool.Add(self.curTip)
    ObjPool.Add(self.nextTip)
    self.curTip = nil
    self.nextTip = nil
    -- TableTool.ClearUserData(self)
end

return My