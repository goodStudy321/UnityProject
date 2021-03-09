--[[
二级分页界面通用基类
]]
EquipTgBase=Super:New{Name="EquipTgBase"}
local My = EquipTgBase

function My:Init(go)
    self.go=go
    self.trans=go.transform
    if not self.tgList then self.tgList={} end
	if not self.togList then self.togList={} end
    if not self.togRedList then self.togRedList={} end
    if not self.eSwatchTg then self.eSwatchTg=Event() end
    self:SetEvent("Add")
    self:InitCustom(go)
end

function My:InitCustom(go)
    -- body
end

function My:InitTog(num)
    local CG=ComTool.Get
    local TF=TransTool.FindChild
    local U = UITool.SetLsnrSelf
    self.togGrid=CG(UIGrid,self.trans,"Grid",self.Name,false)
    local grid = self.togGrid.transform
    for i=1,num do
		local tog=CG(UIToggle,grid,"Tog"..i,self.Name,false)
		U(tog.gameObject,self.Click,self,self.Name)
		self.togList[i]=tog
		local red = TF(tog.transform,"red")
		self.togRedList[i]=red
	end
end
function My:Click(go)
    local name = go.name
	local tp = tonumber(string.sub(name,4))
	self:SwitchTg(tp)
end

function My:SetEvent(fn)

end

--如果传进来的bTp是string,则要自己重写
function My:SwitchTg(bTp,sTp,id)
    if not bTp then iTrace.eError("xiaoyu","传入分页为nil")return end
    if self.bTp==bTp then return end
	if self.bTp then 
        self.togList[self.bTp].value=false 
        local tg = self.tgList[self.bTp]
		if tg then tg:Close() end
	end
    self.bTp=bTp
    self.sTp=sTp
    self.id=id
	self.togList[bTp].value=true	
    self.eSwatchTg(self.bTp)
    local tg = self.tgList[bTp]
    if not tg then return end
    tg.sTp=bTp
    tg:Open()
    self:SwitchTgCustom()
end

function My:SwitchTgCustom()
    -- body
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
    self:CloseCustom()
end

function My:CloseCustom()
    -- body
end

function My:Clean()
    self.bTp=nil
    self.sTp=nil
    self.id=nil
    self:SetEvent("Remove")
    self:DisposeCustom()
    TableTool.ClearUserData(self)
end

function My:CleanCustom()
    ListTool.Clear(self.togList)
    ListTool.ClearToPool(self.tgList)
    ListTool.Clear(self.togRedList)
end

function My:Dispose()
    self:CleanCustom()
    self:Clean()
end

function My:DisposeCustom()
   -- body
end