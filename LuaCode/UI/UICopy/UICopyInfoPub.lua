UICopyInfoPub = UICopyInfoBase:New{Name = "UICopyInfoPub"}

local M = UICopyInfoPub

function M:InitSelf()
    local G = ComTool.Get
    local trans = self.left
    self.lblName = G(UILabel, trans, "Name")
    self.lblTarge = G(UILabel, trans, "Target")
    self.lblDes = G(UILabel, trans, "Des")
end

function M:InitData()  
    local temp = self.Temp
    self.lblName.text = temp.name
    self.lblDes.text = temp.des
    self:UpdateCur()
end

function M:UpdateCur()
    local temp = self.Temp
    local info = CopyMgr.CopyInfo
    local mt = MonsterTemp[tostring(temp.eParam[1])]  
    local name = mt and mt.name or "怪物"
    if temp.eType ~= CopyEType.GUARD then
        self.lblTarge.text = string.format("击败[00FF00FF]%s[-] %d/%d", name, info.Cur or 0, info.totalWave)
    else
        self.lblTarge.text = string.format("守护[00FF00FF]%s[-]", name)
    end
end

return M