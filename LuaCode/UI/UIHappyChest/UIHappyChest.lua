
--[[
欢乐宝箱
--]]

UIHappyChest = UIBase:New{Name = "UIHappyChest"}

require("UI/UIHappyChest/UIHappyChestCell")

local My = UIHappyChest

My.mCellList = {}

function My:InitCustom()
    local rootTrans, des = self.root, self.Name
    local TFC = TransTool.FindChild
    local TF = TransTool.Find
    local USS = UITool.SetLsnrSelf
    local USB = UITool.SetBtnClick
    local CG = ComTool.Get

    self.labTime = CG(UILabel, rootTrans, "CD")
    self.labIngot = CG(UILabel, rootTrans, "labCurIngot/curIngot")
    self.labArrow1 = CG(UILabel, rootTrans, "arrow1/Label")
    self.labArrow2 = CG(UILabel, rootTrans, "arrow2/Label")

    local gridParent = TF(rootTrans, "Grid")
    for i = 1, 3 do
        local go = TFC(gridParent, tostring(i))
        local cell = ObjPool.Get(UIHappyChestCell)
        cell:Init(go)
        self.mCellList[i] = cell
    end

    self:InitActivInfo()
    self:SetEvent("Add")
    self.str = InvestDesCfg["2014"].des

    USB(rootTrans, "btnClose", des, self.OnClickBtnClose, self) --关闭窗口
    USB(rootTrans, "btnHelp", des, self.OnClickBtnHelp, self) --活动说明

    --倒计时
    self.timer = ObjPool.Get(DateTimer)
    self.timer.invlCb:Add(self.UpdateTimer, self)
    self.timer.complete:Add(self.Close, self)

end

function My:SetArrowLab()
    local list = HappyChestMgr:GetPayCondition()
    self.labArrow1.text = string.format("充值满%s元升级为特级大奖", list[2])
    self.labArrow2.text = string.format("充值满%s元升级为土豪巨奖", list[3])
end

function My:UpdateCells()
    local data = HappyChestMgr:GetCellData()
    local rewardData = HappyChestMgr.rewardData
    if not data or not rewardData then
        return
    end
    local mgr = HappyChestMgr
    local list = self.mCellList
    for i = 1, #data do
        if list[i] then
            local str = mgr.configNum .. "0" .. i
            local id = tonumber(str)
            list[i]:UpdateData(data[i], rewardData, id)
        end
    end
end


function My:UpdateTimer()
    self.labTime.text = string.format("活动倒计时:%s",self.timer.remain)
end

function My:SetEvent(fn)
    local mgr = HappyChestMgr
    mgr.eUpLab[fn](mgr.eUpLab, self.UpIngobLab, self)
    mgr.eUpCell[fn](mgr.eUpCell, self.UpdateCells, self)
end


-- 更新累计充值文本
function My:UpIngobLab(accrecharge)
    if accrecharge then
        self.labIngot.text = string.format("%s元", accrecharge)
    end
end


function My:OpenCustom()
    self:SetArrowLab()
    self:UpIngobLab(HappyChestMgr.accrecharge)
    self:UpdateCells()
    HappyChestMgr:DelRedDot()
    self:StartTimer()
    self:UpdateTimer()
end

--打开面板获取活动信息
function My:InitActivInfo()
    local info = NewActivMgr:GetActivInfo(HappyChestMgr.sysID);
    if not info then return end
    HappyChestMgr:SaveActivInfo(info);
end


--开始倒计时
function My:StartTimer()
    local endTm = HappyChestMgr:GetEndTime()
    local startTm = HappyChestMgr:GetStartTime()
    if DateTool.GetServerTimeSecondNow() >= startTm then
        if endTm > 0 then
            local sec =  endTm - DateTool.GetServerTimeSecondNow()
            self.timer.seconds = sec
            self.timer:Start()
        end
    end

end

--点击退出按钮
function My:OnClickBtnClose()
    HappyChestMgr:RedPoint()
    self:Close()
end

--点击信息按钮
function My:OnClickBtnHelp()
    if self.str then
        UIComTips:Show(self.str, Vector3(-350, -250, 0), nil, nil, nil, nil, UIWidget.Pivot.TopLeft)
    end
end

function My:EndTimer()
    if self.timer then
        self.timer:AutoToPool()
    end
    self.timer = nil
end

function My:DisposeCustom()
    self:EndTimer()
    self:SetEvent("Remove")
    TableTool.ClearDicToPool(self.mCellList)
    self.str = nil
end
return My