require("UI/UIEquip/EquipTg")
require("UI/UIEquip/EquipPanel")
require("UI/UIEquip/TipPanel")
UIEquip=UIBase:New{Name="UIEquip"}
local My = UIEquip
My.bTp=nil
My.sTp=nil

function My:InitCustom()
    local TF = TransTool.FindChild
    self.tg=ObjPool.Get(EquipTg)
    self.tg:Init(self.gbj)
    self.equippanel=ObjPool.Get(EquipPanel)
    self.equippanel:Init(TF(self.root,"right"))
    self.equippanel:Open()

    self.tippanel=ObjPool.Get(TipPanel)
    self.tippanel:Init(TF(self.root,"TipPanel"))
    UITool.SetBtnClick(self.root,"CloseBtn",self.Name,self.CloseBtn,self)
end

function My:SetEvent(fn)
    self.tg.eWitchTg[fn](self.tg.eWitchTg,self.WitchTg,self)
end

function My:OpenCustom()
    if self.equippanel then self.equippanel:CreateEquipCellList() end
    self:SetEvent("Add")
end

function My:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end

function My:OpenTabByIdx(t1,t2,t3,t4)
    My.bTp=t1
    My.sTp=t2
    self.tg:SwitchTg(t1,t2,t3)
end

function My:WitchTg()
    if My.bTp==6 or My.bTp==4 then 
        self.equippanel:Close()
    else
        self.equippanel:Open()
    end
    self.equippanel:WitchTg()
end

function My:DisposeCustom()
    self:SetEvent("Remove")
    if self.tg then ObjPool.Add(self.tg) self.tg=nil end
    if self.equippanel then ObjPool.Add(self.equippanel) self.equippanel=nil end
    if self.tippanel then ObjPool.Add(self.tippanel) self.tippanel=nil end
    My.bTp=nil
    My.sTp=nil
end

return My