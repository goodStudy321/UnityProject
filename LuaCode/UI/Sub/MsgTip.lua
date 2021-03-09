--[[
文字显示
]]
MsgTip=UIBase:New{Name="MsgTip"}
local My = MsgTip

function My:InitCustom()
    if not self.labList then self.labList={} end
    local CG = ComTool.Get
    UITool.SetBtnClick(self.root,"Close",self.Name,self.Close,self,false)
    self.centerLab=CG(UILabel,self.root,"centerLab",self.Name,false)
    self.grid=CG(UIGrid,self.root,"Panel/Grid",self.Name,false)
    local grid=self.grid.transform
    for i=1,10 do
        local lab = CG(UILabel,grid,"lab"..i,self.Name,false)
        self.labList[i]=lab
    end
    self.index=0
end

function My:ShowCenterLab(text)
    self.centerLab.gameObject:SetActive(true)
    self.centerLab.text=text
end

function My:ShowLab(text)
    self.grid.transform.parent.gameObject:SetActive(true)
    self.index=self.index+1
    local lab = nil
    if self.index>10 then
        local one = self.labList[1]
        one.transform.parent=nil
        table.remove(self.labList,1 )

        one.transform.parent=self.grid.transform
        table.insert(self.labList,one )
        lab=one
        self.grid:Reposition()
    else
        lab=self.labList[self.index]
    end
    lab.text=text
end

function My:DisposeCustom()
    for i,v in ipairs(self.labList) do
        v.text=""
    end
    ListTool.Clear(self.labList)
end

return My