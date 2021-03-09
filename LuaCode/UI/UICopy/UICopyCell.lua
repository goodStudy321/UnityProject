UICopyCell = Super:New{Name = "UICopyCell"}

local M = UICopyCell

function M:Ctor()
    self.eClick = Event()
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find

    self.go = go
    self.icon = G(UISprite, trans, "Icon")
    self.name = G(UILabel, self.icon.transform, "Name")
    self.score = G(UISprite, self.icon.transform, "Score")
    self.level = G(UILabel, self.icon.transform, "Level")
    self.bg = F(trans, "bg")

    UITool.SetLsnrSelf(go, self.OnClick, self, "", false)
end

function M:OnClick()
    if self.temp then
        self.eClick(self.temp)
    end
end

function M:UpdateData(copyId)
    local k = tostring(copyId)
    local temp = CopyTemp[k]
    if temp then
        self.name.text = temp.name
        local info = CopyMgr.Copy[tostring(temp.type)]
        local copy = info.Dic[k]
        if copy then 
            self.temp = temp
            self:UpdateStar(copy.Star)
            self:UpdateIcon()
            self:UpdateLevel()
        end
    end  
end

function M:UpdateLevel()
    local temp = self.temp
    local state = CopyMgr:IsOpen(temp.id)
    if state then
        self.level.text = string.format("%s%s级", "[00FF00FF]", UIMisc.GetLv(temp.lv))
    else
        self.level.text = string.format("%s%s级开启", "[F21919FF]", UIMisc.GetLv(temp.lv))
    end
end

function M:UpdateFx(bool)
    local temp = self.temp
    local state = CopyMgr:IsOpen(temp.id) and bool
    if state then
        if not self.fx then
            Loong.Game.AssetMgr.LoadPrefab("FX_AnNiu", GbjHandler(self.LoadEffectCb,self))
        else
            self.fx:SetActive(true)
        end
    elseif self.fx then
        self.fx:SetActive(false)
    end
end

function M:LoadEffectCb(go)
    if self.bg then
        self.fx = go
        go.transform:SetParent(self.bg)
        go.transform.localPosition = Vector3.zero
        go.transform.localScale = Vector3.one
        go:SetActive(true)
    else
        self:UnloadFx(go)
    end
end

function M:UnloadFx(go)
    AssetMgr:Unload(go.name, ".prefab", false)
    GameObject.DestroyImmediate(go)
end

function M:UpdateIcon()
    self.icon.spriteName = self.temp.diff
end

function M:SetScale(vec)
    self.icon.transform.localScale = vec
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:IsActive()
    return self.go.activeSelf
end


function M:UpdateStar(Star)
    if Star then    
        UITool.SetNormal(self.icon)
    else
        local copy, isOpen = CopyMgr:GetCurCopy(self.temp.type)
        if isOpen and copy.Temp.id == self.temp.id then
            UITool.SetNormal(self.icon)
        else
            UITool.SetGray(self.icon)
        end
    end
    Star = Star or 0
    self.score.spriteName = "top_".. Star
end

function M:Dispose()
    self.temp = nil
    self.eClick:Clear()
    if self.fx then
        self:UnloadFx(self.fx)
        self.fx = nil
    end
    TableTool.ClearUserData(self)
end

return M