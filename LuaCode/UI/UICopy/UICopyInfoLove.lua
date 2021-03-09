UICopyInfoLove = UICopyInfoBase:New{Name = "UICopyInfoLove"}

require("UI/UICopy/UICopyLoveSelectView")

local M = UICopyInfoLove

M.cellList = {}
M.mId1 = GlobalTemp["55"].Value2[1]
M.mId2 = GlobalTemp["56"].Value2[1]
M.totalTime = BuffTemp["209001"].time

M.isDecrease = false
M.isUp = false
M.isLock = false
M.remainTime = 0
M.curSliderValue = 0

function M:InitSelf()
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    local trans = self.left

    self.lblName = G(UILabel, trans, "Name")
    self.target = G(UILabel, trans, "Target")
    self.grid1 = G(UIGrid, trans, "ori/Reward1/Grid")
    self.grid2 = G(UIGrid, trans, "ori/Reward2/Grid")
    self.oriGbj = FC(trans,"ori")
    self.othGbj = FC(trans,"oth")
    self.wuLab = G(UILabel,trans,"oth/Wu")
    self.rwInfo = FC(trans,"oth/RwdInfo")
    self.rwGrid = G(UIGrid,trans,"oth/RwdInfo/Grid")

    local other = F(self.root, "Other")
    self.other = other
    self.selectView = ObjPool.Get(UICopyLoveSelectView)
    self.selectView:Init(FC(other, "SelectView"))

    self.loveTemp = FC(other, "LoveTemp")
    self.slider = G(UISlider, other, "LoveTemp/Slider")
    self.fx1 = FC(self.slider.transform, "FX1")
    self.fx2 = FC(self.slider.transform, "FX2")

end

function M:Update()
    if self.isLock then return end

    if self.isUp then
        self.curSliderValue = self.curSliderValue + Time.unscaledDeltaTime*self.remainTime
        if self.curSliderValue >= self.remainTime then
            self.curSliderValue = self.remainTime
            self.isUp = false
        end
        self:UpdateSlider()
    elseif self.isDecrease then
        self.curSliderValue = self.curSliderValue - Time.unscaledDeltaTime
        if self.curSliderValue < 0 then
            self.curSliderValue = 0
            self.isDecrease = false
        end
        self:UpdateSlider()
        self:UpdateFx()
    end
end

function M:SetLsnrSelf(key)
    CopyMgr.eMarryCopyIcon[key](CopyMgr.eMarryCopyIcon, self.MarryCopyIcon, self)
    CopyMgr.eMarryCopySelect[key](CopyMgr.eMarryCopySelect, self.MarryCopySelect, self)
    CopyMgr.eMarryCopyFinish[key](CopyMgr.eMarryCopyFinish, self.MarryCopyFinish, self)
    CopyMgr.eMarryCopySweet[key](CopyMgr.eMarryCopySweet, self.MarryCopySweet, self)
end

function M:SetEvent(e)
    local EH = EventHandler
    e("OnUnitDead", EH(self.OnUnitDead, self))
end

function M:OnUnitDead(typeId, pos)
   if typeId == self.mId1 or typeId == self.mId2 then
        local screenpos = Camera.main:WorldToScreenPoint(pos)
        local tPos = UIMgr.Cam:ScreenToWorldPoint(screenpos)
        local del = ObjPool.Get(Del1Arg)
        del:Add(Vector3(tPos.x, tPos.y, 0))
		del:SetFunc(self.SetFx, self)
        AssetMgr:Load("FX_ui_TMD.prefab", ObjHandler(del.Execute, del))
   end
end

function M:SetFx(obj, pos)
    local go = Instantiate(obj)
    ShaderTool.eResetGo(go)
    go.name = "FX_ui_TMD"
    go.transform:SetParent(self.other)
    go.transform.localScale = Vector3.one
    go.transform.position = pos
    self:DOTween(go)
end

function M:DOTween(go)
    TweenPosition.Begin(go, 1, self.loveTemp.transform.localPosition):SetOnFinished(EventDelegate.Callback(function() 
        AssetMgr:Unload(go.name, ".prefab", false)
        GameObject.DestroyImmediate(go)
        self.isLock = false
    end))
end

function M:MarryCopySweet(isDecrease, remainTime) 
    self.isLock = true
    self.isUp = true
    self.remainTime = remainTime 
    self.isDecrease = isDecrease 
end

function M:MarryCopyFinish()
    self.selectView:StopTimer()
    self.selectView:SetActive(false)
end

function M:MarryCopyIcon(itemList, eTime)
    self.selectView:UpdateData(itemList)
    self.selectView:CreateTimer(eTime)
end

function M:MarryCopySelect(id)
    self.selectView:UpdateState(id)
end

function M:InitData()  
    local copyNum,curHonor,maxHonor = CopyMgr:GetCopyNum(self.Temp)
    if copyNum <= 0 then
        self.wuLab.gameObject:SetActive(curHonor >= maxHonor)
        self.rwInfo:SetActive(curHonor < maxHonor)
    end
    self.oriGbj:SetActive(copyNum > 0)
    self.othGbj:SetActive(copyNum <= 0)
    local rwNum = GlobalTemp["201"].Value2[1]
    local pId = GlobalTemp["201"].Value3
    local tab = {{id = pId,value = rwNum}}
    self:UpdateReward(tab, self.rwGrid,1)

    self.lblName.text = self.Temp.name
    self:UpdateReward(GlobalTemp["57"].Value1, self.grid1)
    self:UpdateReward(GlobalTemp["58"].Value1, self.grid2)
    self:UpdateCur()

    local info = CopyMgr.CopyInfo
    self.curSliderValue = info.remainTime or 0
    self.isDecrease = info.isDecrease 
    self:UpdateSlider()
end

function M:UpdateSlider()
    if not LuaTool.IsNull(self.slider) then
        self.slider.value = self.curSliderValue/self.totalTime
    end
end

function M:UpdateFx()
    if LuaTool.IsNull(self.fx1) then return end
    local val = self.curSliderValue/self.totalTime  
    if self.curSliderValue > 0 then
        self.fx1:SetActive(true)
        self.fx2:SetActive(true)
        self.fx2.transform.localPosition = Vector3(val*176-88, 0, 0)
    else
        self.fx1:SetActive(false)
        self.fx2:SetActive(false)
    end
end

function M:UpdateReward(data, grid,scale)
    scale = scale or 0.8
    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(grid.transform, scale)
        cell:UpData(data[i].id, data[i].value)
        table.insert(self.cellList, cell)
    end
    grid:Reposition()
end

function M:UpdateCur()
    local info = CopyMgr.CopyInfo
    if not info then return end
    local cfg = LoveCopyCfg[info.Cur]
    if not cfg then 
        self.target.text = string.format("[00FF00FF]%s[-]", "和对方一起通关副本")
    else
        local mNum = (cfg.pos1 and cfg.pos2) and (cfg.mNum*2) or cfg.mNum  
        self.target.text = string.format("[F4DDBDFF]%s:([00FF00FF]%d[-]/%d)", MonsterTemp[tostring(cfg.mId)].name, info.Sub or 0, mNum)
    end
end

function M:UpdateSub()
    self:UpdateCur()
end

function M:SetMenuStatus(bool)
    self.loveTemp:SetActive(bool)
end


function M:DisposeSelf()
    ObjPool.Add(self.selectView)
    self.selectView = nil
    self.isDecrease = false
    self.isLock = false
    self.isUp = false
    self.remainTime = 0
    self.curSliderValue = 0
end

return M