require("UI/Robbery/UIListSpModItem")
require("UI/Robbery/SpiritG/SpiritBagInfo")
require("UI/Robbery/SpiritG/SPEquipInfo")
require("UI/Robbery/SpiritG/SPCell")
require("UI/Robbery/SpiritG/SPEquipListCell")
require("UI/Robbery/SpiritG/SPSuitInfo")

SpiritGPanel = UILoadBase:New{Name = "SpiritGPanel"}
local My = SpiritGPanel
My.eRedFalg = Event()

local SMIT = UIListSpModItem

function My:Init()
    local root = self.GbjRoot.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local TFC = TransTool.FindChild

    self.gridItem = CG(UIGrid,root,"mods/Grid",name)
    self.modelRoot = TF(root,"modelRoot",name)
    self.item = TF(root,"mods/Grid/item",name)
    self.item.gameObject:SetActive(false)
    self.items = {}
    
    self.flagRed = false
    self.isCurSp = false
    -- self.equipLab = CG(UILabel,root,"equipBtn/lab",name)
    self.desBtn = CG(BoxCollider, root,"desBtn", name)
    
    self.lvLab = CG(UILabel,root,"curName/lvLab",name)
    self.curNameLab = CG(UILabel,root,"curName/lab",name)
    self.lockDesLab = CG(UILabel,root,"LockDes",name)
    self.qDes = TFC(root,"qDes",name)
    self.curDesLab = CG(UILabel,root,"qDes/curdes",name)
    self.nextDesLab = CG(UILabel,root,"qDes/nextdes",name)

    self.bagInfo = ObjPool.Get(SpiritBagInfo)
    self.bagInfo:Init(TF(root, "BagInfo"))

    self.middleInfo = ObjPool.Get(SPEquipInfo)
    self.middleInfo:Init(TF(root, "BagInfo"))

    self.suitInfo = ObjPool.Get(SPSuitInfo)
    self.suitInfo:Init(TF(root, "SelectTip"))

    self.strRed = TFC(root,"BtnStren/red",name)

    USBC(root, "BtnDel", name, self.OnEquipCompose, self)
    USBC(root, "BtnStren", name, self.OnEquipStrength, self)
    USBC(root, "attBtn", name, self.OnAttBtn, self)
    UITool.SetLsnrSelf(self.desBtn, self.OnClickSpDecBtn, self)

    self:InitSpiriteItem()
    self:SetEvent("Add")
    self:RefreshRed()
end

function My:SetEvent(fn)
    local mgr = SpiritGMgr
	mgr.eUpdateSBInfo[fn](mgr.eUpdateSBInfo, self.UpdateSBInfo, self)
	mgr.eUpdateBagInfo[fn](mgr.eUpdateBagInfo, self.RefreshBag, self)
	mgr.eUpdateRedInfo[fn](mgr.eUpdateRedInfo, self.RefreshRed, self)
    -- RobberyMgr.eUpdateSpiRefInfo[fn](RobberyMgr.eUpdateSpiRefInfo, self.SetSpProp, self)
end

function My:OnClickSpDecBtn(go)
    local desInfo = InvestDesCfg["1400"]
    local str = desInfo.des
     UIComTips:Show(str, Vector3(-250,-200,0),nil,nil,nil,nil,UIWidget.Pivot.TopLeft)
end

function My:RefreshRed()
    local redInfo = SpiritGMgr.SpRedInfo --j：战灵id  l:红点状态
    local spItemTab = self.items
    local flagRed = false
    local strState = SpiritGMgr.StrBtnState
    self.strRed:SetActive(strState)
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    for k,v in pairs(spItemTab) do
        for j,l in pairs(redInfo) do
            if k == j then
                v:SetRed(l)
            end
            if l == true then
                flagRed = true
            end
        end
    end
    self.flagRed = flagRed
    self.eRedFalg(flagRed)
end

--属性面板
function My:OnAttBtn()
    local curSpCfg = self.curClickSpCfg
    local suitIdTab = curSpCfg.suitGroup
    self.suitInfo:Open(suitIdTab)
end

--点击灵饰强化
function My:OnEquipStrength()
    local isHaveEquip = self.isHaveEquip
    if isHaveEquip == false then
        UITip.Error("请穿戴装备")
        return
    end
    JumpMgr:InitJump(UIRobbery.Name,3)
    UIMgr.Open(UISpiritStrength.Name)
end

--点击灵饰分解
function My:OnEquipCompose()
    UIMgr.Open(UISpiritCompose.Name)
end

function My:OnClickTipBtn(go)
    if go then
        go.gameObject:SetActive(false)
    end
end

function My:Open()
    self:OnClickItem(self.items["10101"].root)
    -- self.Gbj.gameObject:SetActive(true)
    self:RefreshBag()
    self:RefreshRed()
end

--战灵背包数据更新
function My:RefreshBag()
    self.bagInfo:Refresh()
end

--战灵装备信息更新
function My:UpdateSBInfo()
    self.middleInfo:UpdateCell()
    local equipData = self.spEquipData
    self.isHaveEquip = self:IsHaveEquip(equipData)
end

--获取途径界面回调
function My:OpenGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(192,-165,0))
    ui:CreateCell("商城", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    if name == "商城" then
        JumpMgr:InitJump(UIRobbery.Name,2)
		StoreMgr.OpenStoreId(30402)
	end
end

--判断当前战灵是否解锁
--true:未解锁    false:已经解锁
function My:IsLockCurSp()
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    if spiriteInfo.spiriteTab == nil then
        return true
    elseif spiriteInfo.spiriteTab ~= nil and spiriteInfo.spiriteTab[self.curSpId] == nil then
        return true
    end
    return false
end

function My:InitSpiriteItem()
    local item = self.item
    local Inst = GameObject.Instantiate
    local robSevInfo = RobberyMgr.SpiriteInfoTab
    local tabTemp = {}
    for k,v in pairs(SpiriteCfg) do
        table.insert(tabTemp,v)
    end
    table.sort(tabTemp,function(a,b) return a.spiriteId < b.spiriteId end)
    local len = #tabTemp
    for i = 1,len do
        local go = Inst(item)
        local date = tabTemp[i]
        self:AddItem(date,go,robSevInfo)
    end
    self.gridItem:Reposition()
end

function My:AddItem(info,go,robSevInfo)
    if go == nil then return end
    local trans = go.transform
    local it = ObjPool.Get(SMIT)
    it:Init(go)
    it.root.name = info.spiriteId
    go.gameObject:SetActive(true)
    local modId = tostring(info.spiriteId)
    self.items[modId] = it
    TransTool.AddChild(self.gridItem.transform,trans)
    UITool.SetLsnrSelf(trans, self.OnClickItem, self, nil, false)
    it:InitData(info)
    if robSevInfo.spiriteTab ~= nil and robSevInfo.spiriteTab[info.spiriteId] ~= nil then
        it:SetLock(false)
    end
end

function My:OnClickItem(go)
    local key = go.name
	local item = self.items[key]
	if not item then return end
	if self.SelectItem then
        self.SelectItem:IsSelect(false)
        self.SelectItem:SetActive(false,self.curClickSpCfg.uiMod,self.modelRoot)
	end
    self.curSpId = tonumber(key)
    self.curClickSpCfg = SpiriteCfg[key]
    self:SetSpProp()
	self.SelectItem = item
    self.SelectItem:IsSelect(true)
    SpiritGMgr:SetCurSPId(self.curSpId)
    self:UpdateMiddleInfo()
    self:RefreshBag()
	local data = SpiriteCfg[key]
    self.curNameLab.text = data.name
	if not data then return end
    item:SetActive(true,data.uiMod,self.modelRoot)
end

function My:UpdateMiddleInfo()
    local spId = tostring(self.curSpId)
    local spEquipData = SpiritGMgr.SpiritDic[spId]
    if spEquipData then
        self.spEquipData = spEquipData
        self.middleInfo:UpdateData(spEquipData)
        self.isHaveEquip = self:IsHaveEquip(spEquipData)
    end
end

function My:IsHaveEquip(spEquipData)
    local equipInfo = spEquipData.condList
    for i = 1,#equipInfo do
        local info = equipInfo[i]
        if info.isUse == true then
            return true
        end
    end
    return false
end

function My:SetSpProp()
    local curSpId = self.curSpId
    local spiriteInfo = RobberyMgr.SpiriteInfoTab
    local lv = 1
    if spiriteInfo.spiriteTab == nil or spiriteInfo.spiriteTab[curSpId] == nil then
        self:RefreshSpiInfo(lv)
    else
        lv = spiriteInfo.spiriteTab[curSpId].lv
       self:RefreshSpiInfo(lv)
    end
end

--刷新战灵信息
function My:RefreshSpiInfo(curLv)
    local lvLa = string.format("Lv.%s",curLv)
    local expLab = ""
    local getStateLb = ""
    self.lvLab.text = lvLa
--解锁说明
    local isLock = self:IsLockCurSp()
    local lockDesStr = ""
    if isLock == true then
        lockDesStr = self.curClickSpCfg.tip
    else
        lockDesStr = self.curClickSpCfg.wTip
    end
    self.lockDesLab.gameObject:SetActive(isLock)
    self.qDes:SetActive(not isLock)
    self.lockDesLab.text = lockDesStr
    local tab = self:GetQuility(curLv)
    local curS = tab.cQStar
    local nextS = tab.nQStar
    if curS == 0 then
        curS = ""
    else
        curS = string.format("%s星",curS)
    end
    if nextS == 0 then
        nextS = ""
    else
        nextS = string.format("%s星",nextS)
    end
    local curDes = string.format( "当前可穿戴%s%s%s[-]灵饰",tab.cQColor,tab.cQLab,curS)
    local nextDes = string.format( "Lv.%s可穿戴%s%s%s[-]灵饰",tab.nQlv,tab.nQColor,tab.nQLab,nextS)
    if tab.cQLab == tab.nQLab and tab.cQStar == tab.nQStar then
        nextDes = "已达到可穿戴最高品质"
    end
    self.curDesLab.text = curDes
    self.nextDesLab.text = nextDes
end


function My:GetQuility(spLv)
    local tab = {}
    local quality = self.curClickSpCfg.qLimit
    local curLv = spLv
    local index = 0
    local len = #quality
    for i = 1,len do
        local info = quality[i]
        local lv = info.I --等级
        local qua = info.B --品质
        local star = info.N --星级
        if curLv >= lv then
            index = index + 1
        end
    end
    local cCfg = quality[index]
    local nCfg = quality[index+1]
    if nCfg == nil then
        nCfg = cCfg
    end
    local cQlv = cCfg.I
    local cQua = cCfg.B
    local cStar = cCfg.N
    local nQlv = nCfg.I
    local nQua = nCfg.B
    local nStar = nCfg.N
    tab.cQLab = UIMisc.GetColorLb(cQua)
    tab.cQColor = UIMisc.LabColor(cQua)
    tab.cQStar = cStar
    tab.nQlv = nQlv
    tab.nQLab = UIMisc.GetColorLb(nQua)
    tab.nQColor = UIMisc.LabColor(nQua)
    tab.nQStar = nStar
    return tab
end

function My:CloseC()
    -- self.Gbj.gameObject:SetActive(false)
end

function My:Clear()
    if self.items then
        for k,v in pairs(self.items) do
            v:Dispose()
            ObjPool.Add(v)
            self.items[k] = nil
        end
    end
end

function My:Dispose()
    ObjPool.Add(self.bagInfo)
    ObjPool.Add(self.middleInfo)
    ObjPool.Add(self.suitInfo)
    self.bagInfo = nil
    self.middleInfo = nil
    self.suitInfo = nil
    self.spEquipData = nil
    self.isHaveEquip = nil
    self.flagRed = nil
    self.SelectItem = nil
    self:SetEvent("Remove")
    self:Clear()
    self:CloseC()
    AssetTool.Unload(self.modelRoot.transform)
    -- TableTool.ClearUserData(self)
end