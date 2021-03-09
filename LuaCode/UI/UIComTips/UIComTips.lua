UIComTips = UIBase:New{ Name = "UIComTips"}

local M = UIComTips

function M:InitCustom()
    local content = ComTool.Get(UILabel, self.root, "Content")
    local pivot = ComTool.Get(UIWidget, self.root, "Content")
    local sprName = ComTool.Get(UISprite, self.root, "BG")
    pivot.pivot=self.piv
    UITool.SetLsnrSelf(content, self.Close, self, self.Name, false)
    content.transform.localPosition = self.pos
    content.text = self.content
    sprName.spriteName = self.sprName
    content.fontSize = self.fontSize
    content.spacingX = self.spaceX
    content.spacingY = self.spaceY
    content.overflowWidth = self.maxWidth
end
--改变中心坐标点pivot应该传入如 UIWidget.Pivot.TopLeft
function M:Show(content, pos, fontSize, spaceX, spaceY, maxWidth,Pivot, sprName)
    self.content = content 
    self.pos = pos or Vector3.zero
    self.fontSize = fontSize or 20
    self.spaceX = spaceX or 0
    self.spaceY = spaceY or 0
    self.maxWidth = maxWidth or 0
    self.piv = Pivot or UIWidget.Pivot.Center;
    self.sprName = sprName or "ty_a22"
    UIMgr.Open(self.Name)
end

--清理
function M:Clear()
    self.str = nil 
    self.fontSize = nil
    self.spaceX = nil
    self.spaceY = nil
    self.maxWidth = nil
    self.piv = nil;
end

return M