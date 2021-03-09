--[[
天道情缘
]]
require("UI/UIHeavenLove/HeavenTg")
UIHeavenLove=UIBase:New{Name="UIHeavenLove"}
local My = UIHeavenLove

function My:InitCustom( ... )
    local trans = self.root
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick

    self.tg=ObjPool.Get(HeavenTg)
    self.tg:Init(self.gbj)
    U(trans,"CloseBtn",self.Name,self.Close,self)

   
end

function My:OnEnd()
    self.tg:SwitchTg(self.t1,self.t2,self.t3,self.t4)
end

function My:OpenTabByIdx(t1,t2,t3,t4)
    self.t1=t1
    self.t2=t2
    self.t3=t3
    self.t4=t4
    if not self.timer then
        self.timer=ObjPool.Get(iTimer)
        self.timer.complete:Add(self.OnEnd,self)
        self.timer.seconds=0.1
    end
    self.timer:Start()
end

function My:DisposeCustom( ... )
    if self.tg then ObjPool.Add(self.tg) self.tg=nil end
    if self.timer then self.timer:AutoToPool() self.timer=nil end
end

return My