require("UI/Base/EquipTgBase")
require("UI/UICompound/CompoundTg")
UICompound=UIBase:New{Name="UICompound"}
local My = UICompound
My.bTp=nil
My.sTp=nil
My.id=nil

function My:InitCustom()
    self.tg=ObjPool.Get(CompoundTg)
    self.tg:Init(self.gbj)

    UITool.SetBtnClick(self.root,"CloseBtn",self.Name,self.CloseBtn,self)
end

function My:OpenTabByIdx(t1,t2,t3,t4)
    My.bTp=t1
    My.sTp=t2
    My.id=t3
    self.tg:SwitchTg(My.bTp,My.sTp,My.id)
end

--tp: 跳转的分页   id: 跳转的道具
function My:SwitchTg(bTp,sTp,id)
    local isopen=true
    if bTp==3 or bTp==4 then  --装备合成，饰品合成
        isopen = OpenMgr:IsOpen(19)
    elseif bTp==5 then 
        isopen=OpenMgr:IsOpen(58)
    end
    if isopen==false then UITip.Log("系统未开启") return end
    My.bTp=bTp
    My.sTp=sTp or 1
    My.id=id
    UIMgr.Open(UICompound.Name,My.OpenCb)  
end

function My.OpenCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        if ui.tg then ui.tg:SwitchTg(My.bTp,My.sTp,My.id) end
    end
end

function My:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end

function My:DisposeCustom()
    if self.tg then ObjPool.Add(self.tg) self.tg=nil end
end

return My