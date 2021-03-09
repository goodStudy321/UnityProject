UIDemonArea = UIBase:New{Name = "UIDemonArea"}

require("UI/UIDemon/DemonAreaCell")

local M = UIDemonArea

M.mCellList = {}

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    local G = ComTool.Get

    self.mDes = G(UILabel, trans, "Des")
    self.mBtnHelp = FC(trans, "Des/BtnHelp")
    self.mBtnClose = FC(trans, "BtnClose")
    self.mCD = G(UILabel, trans, "CD")

    local parent = F(trans, "Grid")
    for i=1,3 do
        local go = FC(parent, tostring(i))
        local cell = ObjPool.Get(DemonAreaCell)
        cell:Init(go)
        self.mCellList[i] = cell
    end

    S(self.mBtnClose, self.OnClose, self)
    S(self.mBtnHelp, self.OnHelp, self)

    local strs = StrTool.Split(InvestDesCfg["1901"].des, "|")
    self.str1 = strs[1]
    self.str2 = strs[2]

    self:InitDes()
    self:UpdateCells()
    self:UpdateCD()

    self:SetLsnr("Add")
end

function M:OnClose( )
    self:Close()
    JumpMgr.eOpenJump()
end

function M:SetLsnr(key)
    DemonMgr.eUpdateRoom[key](DemonMgr.eUpdateRoom, self.UpdateRoom, self)
    DemonMgr.eUpdateRoomState[key](DemonMgr.eUpdateRoomState, self.UpdateRoomState, self)
end

function M:UpdateRoom()
    self:UpdateCells()
    self:UpdateCD()
end

function M:OpenTabByIdx(t1, t2, t3, t4)

end

function M:UpdateCells()
    local data = DemonMgr:GetRoomData()
    local list = self.mCellList
    for i=1, #data do
        if list[i] then
            list[i]:UpdateData(data[i])     
        end  
    end
end

function M:UpdateRoomState(id)
    local cell = self.mCellList[id]
    if cell then
        cell:UpdateLock()
    end
    self:UpdateCD()
end


function M:InitDes()
    self.mDes.text = self.str2
end

function M:CreateTimer()
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
        self.timer.fmtOp = 3
        self.timer.apdOp = 2
        self.timer.invlCb:Add(self.InvlCb, self)
        self.timer.complete:Add(self.CompleteCb, self)
    end
    self.timer.seconds = DemonMgr:GetCD()
    self.timer:Reset()
    self.timer:Start()
    self:InvlCb()
    self:SetCDActive(true)
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
    self:SetCDActive(false)
end

function M:SetCDActive(bool)
    self.mCD.gameObject:SetActive(bool)
end

function M:InvlCb()
    if self.timer then
        self.mCD.text = string.format("[F4DDBDFF]距离下一次魔域之门开启还有:[00FF00FF]%s", self.timer.remain)
    end
end

function M:CompleteCb()
    self:SetCDActive(false)
end

function M:UpdateCD()
    if DemonMgr:HadkillAllBoss() or not DemonMgr:IsOpen() then
        self:CreateTimer()
    else
        self:StopTimer()
    end
end

function M:OnHelp()
    if self.str1 then
        UIComTips:Show(self.str1,Vector3(-190,265,0),nil,nil,nil,nil,UIWidget.Pivot.TopLeft)
    end
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearDicToPool(self.mCellList)
    self.str1 = nil
    self.str2 = nil
end

return M 
