TitleDes = Super:New{Name = "TitleDes"}

local M = TitleDes

function M:Init(root)
    local G = ComTool.Get

    self.root = root

    self.lbl_1 = G(UILabel, root, "lbl_1")
    self.lbl_3 = G(UILabel, root, "lbl_3")
    self.lbl_5 = G(UILabel, root, "lbl_5")
    self.lbl_3.spacingY = 10

    local btnSet = TransTool.Find(root, "btnSet")
    UITool.SetLsnrSelf(btnSet, self.Click, self)

    self.btnName = G(UILabel, btnSet, "name")
end

function M:UpdateDes(data)
    if not data then
        self.root.gameObject:SetActive(false)
        return
    else
        self.root.gameObject:SetActive(true)
    end
    self.data = data
    local cfg = data.cfg
    local power = cfg.atk*10 + cfg.hp*0.5 + cfg.arm*10 + cfg.def*10
    self.lbl_1.text = tostring(math.floor(power))
    local str = string.format("[b1a495]攻  击[-]         [ffe9bd]%d[-]\n[b1a495]生  命[-]         [ffe9bd]%d[-]\n[b1a495]破  甲[-]         [ffe9bd]%d[-]\n[b1a495]防  御[-]         [ffe9bd]%d[-]" ,cfg.atk, cfg.hp, cfg.arm, cfg.def)
    if cfg.otherAttr then
        local temp = PropName[cfg.otherAttr.k]
        local name = temp.name
        local value = cfg.otherAttr.v
        if temp.show == 1 then
            value = string.format("%s%%", value * 0.01) 
        end
        str = string.format("%s\n[b1a495]%s[-]     [ffe9bd]%s[-]", str, name, value)
    end
    self.lbl_3.text = str
    self.lbl_5.text = cfg.des
    self.btnName.text = data.isUse == 1 and "卸下" or "佩戴"
end

function M:Click()
    local id = self.data.isUse == 0 and self.data.cfg.id or 0
    TitleMgr:ReqTitleChange(id)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.data = nil
end

return M