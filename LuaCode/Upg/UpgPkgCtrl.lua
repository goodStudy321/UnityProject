--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 9/23/2018, 5:25:15 AM
--=============================================================================

UpgPkgCtrl = {Name="UpgPkgCtrl"}

local My = UpgPkgCtrl

function My:Init()
    euiopen:Add(self.LsnrLogin,self)
end

function My:LsnrLogin(name)
  if(name==UILogin.Name) then
    UpgPkg:Start()
    UpgPkg.complete:Add(self.Complete,self)
  end 
end

function My:Open()
    UIMgr.Open(UIRefresh.Name)
end

function My:Close()
    UIMgr.Close(UIRefresh.Name)
end

function My:Complete()
    UIMgr.Open(UIBBS.Name)
end

return My