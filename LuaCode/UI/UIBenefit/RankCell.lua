RankCell = Super:New{Name = "RankCell"}

local M = RankCell

function M:Init(go)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local trans = go.transform

    self.go = go

    self.value1 = G(UILabel, trans, "Value1")
    self.value2 = G(UILabel, trans, "Value2")
    self.value3 = G(UILabel, trans, "Value3")
    self.value4 = G(UILabel, trans, "Value4")

    self.rank = G(UISprite, trans, "Rank")
    self.rankBg = G(UISprite, trans, "RankBg")
    self.bg = G(UISprite, trans, "Bg")
end

function M:UpdateData(data)
    if not data then return end
    self.value1.text = data.Value1
    self.value2.text = data.Value2
    self.value3.text = data.Value3
    self.value4.text = data.Value4
    self:SetBg(data.Value1)
    self:SetRank(data.Value1)
end


function M:SetBg(id)
    self.bg.color.a = id%2==0 and 1 or 0
end

function M:SetRank(id)
    self.rank.gameObject:SetActive(id<4)
    self.rankBg.gameObject:SetActive(id<4)
    if id == 1 then 
        self.rank.spriteName =  "rank_icon_1"
        self.rankBg.spriteName = "rank_info_g"
    elseif id == 2 then
        self.rank.spriteName =  "rank_icon_2"
        self.rankBg.spriteName = "rank_info_z"
    elseif id == 3 then
        self.rank.spriteName =  "rank_icon_3"
        self.rankBg.spriteName = "rank_info_b"
    end
end


function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Dispose()
    TableTool.ClearUserData(self)
end

return M