--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 11/1/2018, 10:39:15 AM
-- 符文分解标记
--=============================================================================


RuneDecomFlag = Flag:New{Name="RuneDecomFlag"}

local My,base = RuneDecomFlag,Flag


function My:Init()
    base.Init(self)
    RuneMgr.eUpdateBag:Add(self.Update,self)
end

function My:Update()
    self.red = false
    if not RuneMgr.isOpen then return end
    local qt,IsExp = nil,RuneMgr.IsExp
    for k,v in pairs(RuneMgr.bagDic) do
        qt = v.cfg.qt
        if (qt==1) then
            self.red = true
        elseif (qt==2) then
            self.red = true
        elseif (IsExp(v.cfg)) then
            self.red = true
        end
        if self.red then break end
    end
    self.eChange(self.red)
end

return My
