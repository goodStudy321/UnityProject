gmItem=Super:New{Name = "gmItem"}
local My = gmItem

function My:init(go,k,v,num )
    self.go=go
    self.root=go.transform
    self.info=ComTool.Get(UILabel,self.root,"info")
    self.info.text=v
    self.id=k
    self.name=v
    self.num=num
    UITool.SetBtnSelf(self.root,self.doChoose,self)
end

function My:doChoose( )
    UIGM:showChoose(self.id,self.name,self.num)
    UIGM.sv:SetActive(false)
    UIGM:Clear()
end
return My