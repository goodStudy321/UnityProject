UIAdvGetWayItem = Super:New{Name = "UIAdvGetWayItem"}
local My = UIAdvGetWayItem

function My:Init(root)
    local name = self.Name
    local Find = TransTool.Find
    local CG = ComTool.Get
    local SetS = UITool.SetLsnrSelf
    local transSelf = root.gameObject
    self.wayName = CG(UILabel,root,"lab",name)
    SetS(transSelf,self.OnSelfClick,self,name)
end

--点击获取途径
function My:OnSelfClick(go)
    local name = go.name
    if name == "sczj" then --坐骑商城
        JumpMgr:InitJump(UIAdv.Name,1)
        self.propid = 30301
        self:OpenShop()
    elseif name == "xflj" then --仙峰论剑
        local isOpen = ActivityMsg.ActIsOpen(10002)
        if isOpen then
            JumpMgr:InitJump(UIAdv.Name,2)
            UIArena.OpenArena(2)
        else
            UITip.Error("活动未开启")
            return
        end
    elseif name == "zxzc" then --诛仙战场
        local isOpen = ActivityMsg.ActIsOpen(10001)
        if isOpen then
            JumpMgr:InitJump(UIAdv.Name,2)
            UIArena.OpenArena(4)
        else
            UITip.Error("活动未开启")
            return
        end
    elseif name == "cwfb" then --宠物副本  LivenessInfo
        local other,isOpen = CopyMgr:GetCurCopy("7")
        if isOpen then
            JumpMgr:InitJump(UIAdv.Name,3)
            -- UIMgr.Open(UICopy.Name, self.OpenPetCopy, self)
            UICopy:Show(CopyType.SingleTD)
        else
            UITip.Error("系统未开启")
        end
    elseif name == "sccw" then --宠物商城
        JumpMgr:InitJump(UIAdv.Name,3)
        self.propid = 30361
        self:OpenShop()
    elseif name == "qyzd" then --逍遥神坛
        local isOpen = ActivityMsg.ActIsOpen(10008)
        if isOpen then
            JumpMgr:InitJump(UIAdv.Name,5)
            UIMgr.Open(UITopFightIt.Name)
        else
            UITip.Error("活动未开启")
        end
    end
end

--打开商城界面
function My:OpenShop()
    local storeId = StoreMgr.GetStoreId(4,self.propid)
	StoreMgr.selectId = storeId
	StoreMgr.OpenStore(4)
end

-- --打开宠物副本
-- function My:OpenPetCopy(name)
--     local ui = UIMgr.Get(name)
-- 	if(ui)then
-- 		ui:SetPage(4)
-- 	end
-- end


--设置获取途径名字
function My:GetWayName(wayName)
    self.wayName.text = wayName
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
end

return My