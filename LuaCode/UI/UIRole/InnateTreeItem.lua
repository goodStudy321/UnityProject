
InnateTreeItem=Super:New{Name="InnateTreeItem"}
local My=InnateTreeItem

function My:Init( go,tree,goname,index )
    self.index=index
    self.root=go.transform;
    self.go=go
    go.name=goname
    self.tree=tree;
    local TF = TransTool.Find
	local TFC = TransTool.FindChild
	local US = UITool.SetLsnrSelf
    local CG = ComTool.Get
    self.Selcet=TFC(self.root,"select")
    self.Selcet:SetActive(false )
    self.txtName=CG(UILabel,self.root,"name")
    local name = InnateMgr.TreeNameLst[tree]
    if name==nil then
        iTrace.eError("soon","天赋页签表第一行需要第： "..tree)
        name="天赋"
    end
    self.txtName.text=name
    US(go,self.OnClock,self,self.Name,false)
end

function My:Unlock(  )
    
end

function My:setIndex( index )
    self.index=index
end

function My:OnClock(  )
    InnateTree:Selcet(self.index)
end

function My:onSelcet( b )
    self.Selcet:SetActive(b)
end

function My:Dispose()
    soonTool.Add(self.go,"InnateTreeItem",true)
end

return My;