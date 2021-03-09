AwardItem = Super:New{Name = "AwardItem"}

local M = AwardItem

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrSelf

function M:Init(go)
    self.go = go
    self.trans = go.transform
    local trans = self.trans

    self.icon = C(UISprite,trans,"icon",des,false)
    self.iconObj = self.icon.gameObject
    self.sel = T(trans,"sel")
    self.tx = T(trans,"UI_niu_B")
    self.tx:SetActive(false)
end

function M:InitItem(data)
    self.data = data
    local index = data.id
    self.go.name=100+index
    self.index=index
    local sex = User.MapData.Sex
    if sex == 1 then
        if index < 10 then
            self.icon.spriteName = "sm_b0"..index
        else
            self.icon.spriteName = "sm_b"..index
        end
    else
        if index < 10 then
            self.icon.spriteName = "sm_c0"..index
        else
            self.icon.spriteName = "sm_c"..index
        end
    end
    self:UpState()
end

function M:UpState()
    local state = self.data.value
    self.state=state
    local isAward = self.data.isAward
    local type_id = self.data.type_id
    if state then
        if type_id~=0 then
            if not self.cell then
                self.cell = ObjPool.Get(UIItemCell)
                self.cell:InitLoadPool(self.iconObj.transform,0.9)
            end
            self.cell:SetActive(true)
            self.cell:UpData(type_id)
        else
            self:Mask(true)
        end
    else
        self:Mask(false)
    end
end

function M:HideCell(value)
    if self.cell then
        self.cell:SetActive(value)
    end
end

function M:Mask(value)
    if value then
        UITool.SetGray(self.iconObj)
    else
        UITool.SetNormal(self.iconObj)
    end
end
-- 选择
function M:OnPlay()
    self:Sel(true)
end
function M:ChgState(date)
    self.data=date
    self.tx:SetActive(false)
    self.tx:SetActive(true)
    self:UpState()
end

function M:Sel(value)
    self.sel:SetActive(value)
end

function M:Show(value)
    self.go:SetActive(value)
end

function M:Dispose()
    if self.cell then
        self.cell:SetActive(true)
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
        self.cell = nil
    end
    self:Sel(false)
    soonTool.Add(self.go,"FeverFindItem",true)
    TableTool.ClearUserData(self)
end

return M