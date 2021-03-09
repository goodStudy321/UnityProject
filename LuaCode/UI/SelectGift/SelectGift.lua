--[[
防具自选礼包
--]]
SelectGift=UIBase:New{Name="SelectGift"}
local My = SelectGift

function My:InitCustom()
    local CG=ComTool.Get
	local TF=TransTool.FindChild 
    self.grid=CG(UIGrid,self.root,"Grid",self.Name,false)
    self.gridWid=CG(UIWidget,self.root,"Grid",self.Name,false)
    self.labGrid=CG(UIGrid,self.root,"LabGrid",self.Name,false)
    self.labPre=TF(self.labGrid.transform,"Label")
    if not self.list then self.list={} end
    if not self.lablist then self.lablist={} end

    UITool.SetBtnClick(self.root,"CloseBtn",self.Name,self.Close,self)
    UITool.SetBtnClick(self.root,"Select",self.Name,self.OnSelect,self)
end

function My:UpData(id)
    self:CleanCell()
    self.id=id
    local type_id=PropMgr.tbDic[tostring(self.id)].type_id
    local gift = EquipGift[tostring(type_id)]
    if not gift then iTrace.eError("xiaoyu","装备自选礼包表为空 id: "..tostring(type_id))return end
    local list = gift.giftList
    local count = #list
    local x,y = math.modf( count/4 )
    if y>0 then x=x+1 end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform,0.8)   
        local num = v.val
        local tId = v.id
        cell:UpData(tId,num)
        cell.trans.name=tostring(i)
        self:ShowName(tId)
        self.list[i]=cell

        cell.eClickCell:Add(self.OnClick,self)
        
    end
    self.gridWid.height=self.grid.cellHeight*x
    self.grid.repositionNow=true 
    self.labGrid.repositionNow=true
end

function My:ShowName(tId)
    local item = UIMisc.FindCreate(tId)
    local name = UIMisc.LabColor(item.quality)..item.name
    local go = GameObject.Instantiate(self.labPre)
    go:SetActive(true)
    go.transform.parent=self.labGrid.transform
    go.transform.localScale = Vector3.one
    go.transform.localPosition = Vector3.zero
    local lab = go.transform:GetComponent(typeof(UILabel))
    lab.text=name
    table.insert(self.lablist, go)
end

function My:OnClick(go)
    local name = go.name
    for i,v in ipairs(self.list) do
        v:Select(false)
    end
    self.index=tonumber(name)
    local cell = self.list[self.index]
    cell:Select(true)
end

 --选择装备
function My:OnSelect()
    if not self.index then UITip.Log("未选择道具") return end
    PropMgr.ReqSelectGift(self.id,self.index)
    self:Close()
end

function My:CleanCell()
    while #self.list>0 do
        local cell = self.list[#self.list]
        cell:DestroyGo()
        cell.eClickCell:Remove(self.OnClick,self)
        ObjPool.Add(cell)
        self.list[#self.list]=nil
    end

    while #self.lablist>0 do
        local go = self.lablist[#self.lablist]
        Destroy(go)
        self.lablist[#self.lablist]=nil
    end
end

function My:CloseCustom()
   self:CleanCell()
   self.id=nil
   self.index=nil
end

return My