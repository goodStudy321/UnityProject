MvBuyView = Super:New{Name = "MvBuyView"}

local M = MvBuyView

function M:Init(go)
    local trans = go.transform
    local SC = UITool.SetLsnrClick
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local G = ComTool.Get

    self.go = go

    self.des = G(UILabel, trans, "Des")
    self.cond1 = G(UILabel, trans, "Cond1")
    self.cond2 = G(UILabel, trans, "Cond2")

    SC(trans, "BtnClose", self.Name, self.Close, self)
    SC(trans, "BtnNo", self.Name, self.Close, self)
    SC(trans, "BtnYes", self.Name, self.OnYes, self)
end

function M:Close()
    self:SetActive(false)
end

function M:Open()
    local lv = User.MapData.Level
    local vip = VIPMgr.vipLv
    local cfg = SBOpenCfg
    local num = SoulBearstMgr:GetCanActNum()  --已解锁数量
    local nNum = num+1
    local temp = cfg[nNum]
    if not temp then return end
    local b1 = lv >= temp.level or (temp.vip and vip >= temp.vip)
    local b2 = true
    local item = temp.item
    if item then
        if PropMgr.TypeIdByNum(item.k) < item.v then
            b2 = false
        end
    end
    self.canOpen = b1 and b2
    self.des.text = string.format("解锁第%d只魂兽(目前可激活%d只)", nNum, num) 
    local str = b1 and "[00FF00FF](已达成)[-]" or "[F21919FF](未达成)[-]"
    if temp.vip and temp.vip > 0 then
        self.cond1.text = string.format("角色达到%s级或VIP达到%d%s", UIMisc.GetLv(temp.level) , temp.vip, str)
    else
        self.cond1.text = string.format("[F4DDBDFF]角色达到%s级%s", UIMisc.GetLv(temp.level), str)
    end
    if item then
        self.cond2.gameObject:SetActive(true)
        local num = PropMgr.TypeIdByNum(item.k)
        local color = num >= item.v and "[00FF00FF]" or "[F21919FF]"
        self.cond2.text = string.format("[F4DDBDFF]消耗道具: [F39800FF]%s[-] (%s%s[-][00FF00FF]/%s[-])", ItemData[tostring(item.k)].name, color, num, item.v)
    else
        self.cond2.gameObject:SetActive(false)
    end
    self:SetActive(true)
end

function M:OnYes()
    if self.canOpen then
        SoulBearstMgr:ReqMythicalEquipAddNum()
    else
        UITip.Log("解锁条件不足")
    end
    self:Close()
end

function M:SetActive(state)
    self.go:SetActive(state)
end


function M:Dispose()
    TableTool.ClearUserData(self)
end

return M