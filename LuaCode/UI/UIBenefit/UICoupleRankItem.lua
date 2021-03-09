UICoupleRankItem = Super:New{Name = "UICoupleRankItem"}
local M = UICoupleRankItem

local C = ComTool.Get
local T = TransTool.FindChild

function M:Init(obj)
    self.obj = obj
    local trans = obj.transform
    self.v1 = C(UILabel,trans,"v1",self.Name)
    self.v2 = C(UILabel,trans,"v2",self.Name)
    self.v3 = C(UILabel,trans,"v3",self.Name)
    self.v4 = C(UILabel,trans,"v4",self.Name)
    self.bg = C(UISprite,trans,"bg",self.Name)
end

function M:ShowItem(data)
    if not data then return end
    self.bg.gameObject:SetActive(false)
    if data.rank == 1 then
        self.bg.gameObject:SetActive(true)
        self.bg.spriteName = "rank_icon_1"
    elseif data.rank == 2 then
        self.bg.gameObject:SetActive(true)
        self.bg.spriteName = "rank_icon_2"
    elseif data.rank == 3 then
        self.bg.gameObject:SetActive(true)
        self.bg.spriteName = "rank_icon_3"
    end
    self.v1.text = data.rank
    self.v2.text = data.Mname
    self.v3.text = data.Wname
    self.v4.text = data.friendly
end

function M:Show(value)
    self.obj:SetActive(value)
end

function M:Dispose()
    
end

return M