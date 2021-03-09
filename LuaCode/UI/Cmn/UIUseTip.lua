UIUseTip = UIBase:New{Name = "UIUseTip"}
local M = UIUseTip

function M:InitCustom()
    local SC = UITool.SetLsnrClick
    local G = ComTool.Get

    local root = self.root

    root.localPosition = self.pos or Vector3.zero
    self.info = G(UILabel, root, "Info")
    self.Status = G(UILabel, root, "Status")
    self.btnName = G(UILabel, root, "BtnOk/Name")
    self.parent = TransTool.Find(root, "item")

    if self.name then
        self.btnName.text = self.name
    end

    SC(root, "BtnClose", "", self.OnClose, self)
    SC(root, "BtnOk", "", self.OnOk, self)

    self:UpdateItem()
    self:UpdateStatus()
    self:UpdateInfo()
end

function M:OnOk()
    local cb = self.cb
    local obj = self.obj
    self:Close()
    if obj and cb then
        cb(obj)
    end
end

function M:OnClose()
    local closeCb = self.closeCb
    local obj = self.obj
    self:Close()
    if obj and closeCb then
        closeCb(obj)
    end
    
end

function M:Show(itemData, status, cb, obj, pos, name, closeCb)
    self.itemData = itemData
    self.status = status
    self.cb = cb
    self.obj = obj
    self.pos = pos
    self.name = name
    self.closeCb = closeCb
    UIMgr.Open(UIUseTip.Name)
end

function M:UpdateItem()
    if not self.itemData then
        return
    end
    if not self.item then
        self.item = ObjPool.Get(UIItemCell)
    end
    self.item:InitLoadPool(self.parent, 1, self)
    self.item:UpData(self.itemData)
end

function M:LoadCD(go)
    -- go:GetComponent(typeof(BoxCollider)).enabled = false
end

function M:UpdateStatus(str)
    self.Status.text = self.status or ""
end

function M:UpdateInfo(str)
    self.info.text = self.itemData.name or ""
end

function M:ConDisplay()
	do return true end
end


function M:Clear()
    if self.item then
        ObjPool.Add(self.item)
        self.item = nil
    end
    self.itemData = nil
    self.status = nil
    self.cb = nil
    self.obj = nil
    self.name = nil
    self.closeCb = nil
end


return M