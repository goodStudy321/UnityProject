HeadPhoto = Super:New{Name = "HeadPhoto"}
local M = HeadPhoto

function M:Init(obj)
    self.obj = obj
    self.objTrans = self.obj.transform

    local C = ComTool.Get
    local T = TransTool.FindChild

    self.selfPhoto = T(self.objTrans,"Texture")
    --self.who = T(self.objTrans,"who")
    self.tex = C(UITexture,self.objTrans,"Texture")
end

function M:Choose(category,isHas)
    if self.texName then
        AssetMgr:Unload(self.texName,false)
        self.texName = nil
    end
    if isHas == true then
        self.texName = string.format( "tx_0%s.png", category)
        AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
    end
    self.selfPhoto:SetActive(isHas)
    --self.who:SetActive(isWho)
end

function M:SetIcon(tex)
    self.tex.mainTexture = tex
end

function M:Dispose()
    AssetMgr:Unload(self.texName,false)
    self.texName = nil
end

return M