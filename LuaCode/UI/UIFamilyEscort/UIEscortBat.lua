UIEscortBat = UIBase:New{Name = "UIEscortBat"}

local M = UIEscortBat

M.mHeadsInfo = {}

function M:InitCustom()
    local trans = self.root
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local SC = UITool.SetLsnrClick 

    self:CreateOffLHead(FC(trans, "LeftHead"), 1)
    self:CreateOffLHead(FC(trans, "RightHead"), 2)

    self:RefreshHead()

    SC(trans, "PassBtn", "", self.OnPass, self)
    self:SetEvent(EventMgr.Add)
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    OffLBat.eRefresh[key](OffLBat.eRefresh, self.RefreshHead, self)
end

function M:SetEvent(fn)
    fn("ChangeOffLInfo",EventHandler(self.ChangeInfo,self))
end

function M:ChangeInfo(isEnd,roleId,curHp)
    if isEnd == true then
        self:OnPass()
        return
    end
    local list = self.mHeadsInfo;
    for i = 1, #list do
	    local info = list[i];
	    if tostring(info.roleId) == tostring(roleId) then
		    info:RefreshHp(curHp)
		    return
	    end
    end
end

function M:CreateOffLHead(go, index)
    local offLHead = ObjPool.Get(OffLHead)
    offLHead:InitUIInfo(go)
    self.mHeadsInfo[index] = offLHead
end

function M:RefreshHead()
    if OffLBat.HeadDatas == nil then
        return;
    end
    local id = User.instance.MapData.UID;
    id = tostring(id);
    for k,v in pairs(OffLBat.HeadDatas) do
        if v.roleId == id then
            self.mHeadsInfo[1]:RefreshUI(v, true);
        else
            self.mHeadsInfo[2]:RefreshUI(v, true);
        end
    end
end

function M:OnPass()
    EventMgr.Trigger("EGToCSharp",FamilyEscortMgr:GetBatResult())
    self:Close()
    OffLBat.Clear()
    FamilyEscortMgr:OpenEndPanel()
end

function M:ConDisplay()
	do return true end
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    self:SetEvent(EventMgr.Remove)
    TableTool.ClearDicToPool(self.mHeadsInfo)
end

return M