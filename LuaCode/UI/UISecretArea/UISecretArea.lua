--[[
秘境玩法
]]
require("UI/UISecretArea/AreaJoin")
require("UI/UISecretArea/AreaNoJoin")
UISecretArea=UILoadBase:New{Name="UISecretArea"}
local My = UISecretArea

function My:Init()
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local UB = UITool.SetBtnClick
    self.root = self.GbjRoot
    --self.openState=CG(UILabel,self.root,"OpenPanel/openState",self.Name,false)
    self.NoJoin=TF(self.root,"NoJoin")
    self.Join=TF(self.root,"Join")
end

function My:Open()
    --SecretAreaNetwork:ReqPosInfo()
    SecretAreaMgr.Open()
    --self:UpData()
    SecretAreaMgr.ReqInfo()
    if not self.AreaJoin then 
        self.AreaJoin=ObjPool.Get(AreaJoin) 
        self.AreaJoin:Init(self.Join) 
    end
    self.AreaJoin:Open()
end

-- function My:UpData()
--    local isopen = SecretAreaMgr.isOpen
--    local isJoin = SecretAreaMgr.isJoin
--    if isopen==true then
--         SecretAreaMgr.ReqInfo()
--         if not self.AreaJoin then 
--             self.AreaJoin=ObjPool.Get(AreaJoin) 
--             self.AreaJoin:Init(self.Join) 
--         end
--         self.AreaJoin:Open()
--    else
--         if not self.AreaNoJoin then
--             self.AreaNoJoin=ObjPool.Get(AreaNoJoin)
--             self.AreaNoJoin:Init(self.NoJoin)
--         end
--         self.AreaNoJoin:Open()
--    end

--    self.openState.text=isopen==true and "[f9ab47]开启状态：[-][f4ddbd]开启[-]" or "[f9ab47]开启状态：[-][f4ddbd]未开启[-]"
-- end

function My:CloseC()
    if self.AreaJoin then
        self.AreaJoin:Close()
    end
end


function My:Dispose()
   if self.AreaJoin then ObjPool.Add(self.AreaJoin) self.AreaJoin=nil end
   if self.AreaNoJoin then ObjPool.Add(self.AreaNoJoin) self.AreaNoJoin=nil end
   SecretAreaMgr.timer:Stop()
end

-- return My