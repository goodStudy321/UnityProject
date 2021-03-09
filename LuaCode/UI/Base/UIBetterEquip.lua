--[[
穿戴高品质装备提示    
]]
UIBetterEquip=UIBase:New{Name="UIBetterEquip"}
local My = UIBetterEquip
My.tb=nil

function My:InitCustom()
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    local trans = self.root
    local bg=TF(trans,"bg").transform
    self.cell=ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(bg,0.7,nil,nil,nil,Vector3.New(-72.34,0,0))
    self.equipName=CG(UILabel,bg,"equipName",self.Name,false)
    self:Lock(true)
    UITool.SetLsnrSelf(self.LockGo.transform,self.Close,self,self.Name)
    self.timer=ObjPool.Get(iTimer)
    self.timer.complete:Add(self.Close,self)
end

function My:OpenCustom()
    self:UpData()
end

function My:UpData()
    self.timer:Stop()
    self.timer:Start(8)
    local tb = self.tb
    local item = UIMisc.FindCreate(tb.type_id)
    self.cell:TipData(tb)
    self.equipName.text=UIMisc.LabColor(item.quality)..item.name
end


function My.OpenBetterEquip(tb)
    My.tb=tb
    UIMgr.Open(UIBetterEquip.Name)
end

function My:DisposeCustom()
    if self.timer then 
        self.timer:AutoToPool()
        self.timer=nil
     end
end



return My