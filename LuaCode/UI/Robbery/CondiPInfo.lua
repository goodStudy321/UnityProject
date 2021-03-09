CondiPInfo = Super:New{Name = "CondiPInfo"}
local My = CondiPInfo

function My:Init(go)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local UC = UITool.SetLsnrClick
    local TFC = TransTool.FindChild

    self.lvLab = CG(UILabel,root,"lvLab",name,false)
    self.fightLab = CG(UILabel,root,"fightLab",name,false)
    self.spiriteLab = CG(UILabel,root,"spiriteLab",name,false)
    self.practiceLab = CG(UILabel,root,"practiceLab",name,false)
    
    UC(root,"consume/wayBtn",name,self.GetWayBtn,false)
    self.conLab = CG(UILabel,root,"consume/conLab",name,false)

    self.consumeG = TFC(root,"consume",name)
    self.consumeG:SetActive(false)

    self.item = TF(root,"consume/item",name)

    self.itemObj = nil

    PropMgr.eUpdate:Add(self.SetItemNum, self)
end

function My:UpCellList(index)
    local cur = AmbitCfg[index]
    local items = cur.itemDic
    local len = #items
    local flag = len > 0
    local consume = self.consumeG
    consume:SetActive(flag)
    if not flag then return end
    if self.curPropId == items[1].k then
        return
    end
    local itemid = tostring(items[1].k)
    local itemData = ItemData[itemid]
    self.conLab.text = string.format("[99886b]渡劫消耗:[-]        %s[-]",itemData.name) 
    self.item.gameObject.name = itemid
    self.itemObj = ObjPool.Get(UIItemCell)
    self.itemObj:Init(self.item)
    self.itemObj:UpData(items[1].k, ItemTool.GetConsumeOwn(items[1].k, items[1].v))
    self.curPropId = items[1].k
end

function My:Clear()
    if self.itemObj then
        GameObject.Destroy(self.itemObj.trans.gameObject)
        self.itemObj:DestroyGo()
        ObjPool.Add(self.itemObj)
        self.itemObj = nil
    end
end

function My:SetItemNum()
    if self.itemObj then
        local itemid = tostring(self.curPropId)
        local propNum = PropMgr.TypeIdByNum(itemid)
        self.itemObj:UpLab(propNum)
    end
end

function My:AddOnePropUp()
    PropMgr.eUpdate:Add(self.SetItemNum, self)
    self.isAlAdd = true
end

function My:RePropUp()
    PropMgr.eUpdate:Remove(self.SetItemNum, self)
end

function My:GetWayBtn()
    -- UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
end

function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	-- ui:SetPos(Vector3(85,-110,0))
	ui:CreateCell("挂机", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    UIMgr.Open(UIMapWnd.Name)
end

function My:Dispose()
    self:Clear()
    PropMgr.eUpdate:Remove(self.SetItemNum, self)
    self.curPropId = nil
    self.itemObj = nil
    TableTool.ClearUserData(self)
end
