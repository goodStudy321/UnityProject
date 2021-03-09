UIPetDevourPack = UIBase:New{Name = "UIPetDevourPack"}

require("UI/UIPet/PetPackCell")

local My = UIPetDevourPack
local Players = UnityEngine.PlayerPrefs

My.Quality = {"红色装备", "橙色装备", "紫色装备", "全部装备"}
My.Step = {"十五阶以下", "十四阶以下","十三阶以下","十二阶以下","十一阶以下","十阶以下","九阶以下","八阶以下", "七阶以下", "六阶以下","五阶以下","四阶以下","全部等阶"}

--1白色   2蓝色    3紫色    4橙色    5红色   6粉色
My.RealQuality = {5,4,3,100}
My.RealStep = {15,14,13,12,11,10,9,8,7,6,5,4,100}

My.cellList = {}
My.selectList = {}
My.showCompExp = 0
My.curStar = 0

function My:InitCustom()
    -- Players.DeleteAll()
    local trans = self.root
    -- self.root.transform.localPosition = Vector3.New(0,0,1100)
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    self.quality = G(UIPopupList, trans, "QualityMenu")
    self.labQua = G(UILabel, trans, "QualityMenu/Label")
    self.step = G(UIPopupList, trans, "StepMenu")
    self.labStep = G(UILabel, trans, "StepMenu/Label")
    self.sView = G(UIScrollView, trans, "ScrollView") 
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.vipDesLab = G(UILabel, trans, "vDesLab")
    self.expLab = G(UILabel,trans,"GetExp")
    self.star = G(UIToggle, trans, "starTog")
    self.slidSp = G(UISprite,trans,"SlidBg/slid")
    self.slidLab = G(UILabel,trans,"SlidBg/lab")
    self.propNum = G(UILabel,trans,"propNum")
    self.prefab = FC(self.grid.transform, "Cell")
    self.prefab:SetActive(false)
    self.proTex = G(UITexture,trans,"proBg/tex",name)
    self.proBox = G(BoxCollider,trans,"proBg",name)

    self.composeBtn = FC(trans, "Button")
    self.btnClose = FC(trans, "closeBtn")
    S(self.composeBtn,self.OnComposeBtn,self)
    S(self.btnClose, self.Close, self)
    S(self.star, self.OnStarSelect, self,nil, false)

    -- local transP = F(trans, "itemTran")
    -- local propId = GlobalTemp["149"].Value3
    -- self.itemPropObj = ObjPool.Get(Cell)
    -- self.itemPropObj:InitLoadPool(transP,0.8)
    -- self.itemPropObj:UpData(propId)
    S(self.proBox.gameObject, self.OnClickProp, self, nil, false)

    self:ShowVipDes()
    self.showCompExp = PetMgr.Exp
    
    self:InitPopupList(self.quality, self.Quality)
    self:InitPopupList(self.step, self.Step)
    
    -- self:OpenCompose(3,12)
    
    EA(self.quality.onChange, EC(self.OnQuaSelect, self))
    EA(self.step.onChange, EC(self.OnStepSelect, self))
    
    
    self:SetEvent("Add")
end

function My:OpenCustom()
    --默认选中紫色，四阶，零星
    self:UpdatePopVal(3, 12, 0)
    self:ShowData()
    self:InitProTex()
end

--加载背景贴图
function My:InitProTex()
    local propId = GlobalTemp["149"].Value3
    propId = tostring(propId)
    local iconPath = ItemData[propId].icon
    AssetMgr:Load(iconPath,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(icon)
    self.proTex.mainTexture = icon
    self.TName = self.proTex.mainTexture.name
end

function My:UnLoadProTex()
    if self.TName == nil then
        return
    end
    AssetTool.UnloadTex(self.TName)
    self.TName = nil
end

--点击显示道具tip
function My:OnClickProp()
    UIMgr.Open(PropTip.Name, self.ShowTip, self)
end

function My:ShowTip(name)
    local ui = UIMgr.Get(name)
    local id = GlobalTemp["149"].Value3
    ui:UpData(tostring(id))
end

--道具刷新
function My:ShowData()
    local data = PropMgr.GetQUARANKSTART(100, 100, 0)
    self:UpdateData(data)
end

--打开界面
function My.OpenPetDevPack()
    local lockStateCfg,isOpen = PetMgr:IsOpenDevour()
    local name = lockStateCfg.floorName
    if isOpen == false then
        local str = name .. "开启"
        UITip.Error(str)
        return
    end
    UIMgr.Open(UIPetDevourPack.Name)
end

function My:SetEvent(fn)
    local mgr = PetMgr
    mgr.eUpdatePetExp[fn](mgr.eUpdatePetExp, self.RefreshBag, self)
    PropMgr.eUpdate[fn](PropMgr.eUpdate,self.RefreshBag, self)
end

function My:InitPopupList(popupList, list)
    popupList:Clear()
    for i=1,#list do
        popupList:AddItem(list[i])
    end
    -- popupList.value = list[#list]
end

function My:UpdateData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(PetPackCell)
            item:Init(go)
            item.eClick:Add(self.OnClick,self)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.sView:ResetPosition()
    self.grid:Reposition()
end

function My:ClearSelectData()
    self.showCompExp = PetMgr.Exp
    self.expLab.text = self.showCompExp

    -- for k,v in pairs(self.selectList) do
    --     self.selectList[k] = nil
    -- end
    TableTool.ClearDic(self.selectList)
end

function My:OnClick(isSelect, data)
    if isSelect then
        TableTool.Add(self.selectList, data, "id")
    else
        TableTool.Remove(self.selectList, data, "id")
    end
    self:ShowComposeExp(isSelect,data)
end

--选中物体
function My:SelectItem()
    self:ClearSelectData()
    local list = self.cellList
    local curQ = self.curQuality
    local curS = self.curStep
    local curSt = self.curStar
    local curShowExp = 0
    for i=1,#list do
        if list[i]:IsActive() == false then
            return
        end
        list[i]:SetHighlight(false)
        local typeId = list[i].data.type_id
        local typeId = tostring(typeId)
        -- local cfg = ItemData[typeId]
        local comExp = 0
        local cfg = EquipBaseTemp[typeId]
        if cfg then
            comExp = cfg.petExp
        else
            cfg = ItemData[typeId]
            if cfg and cfg.uFxArg then
                local count = PropMgr.TypeIdByNum(typeId)
                comExp = cfg.uFxArg[1] * count
            end
        end

        local quality = ItemData[typeId].quality
        local equip = EquipBaseTemp[tostring(typeId)]						
        local step = 0
        local star = 0
        if equip then
            step = equip.wearRank or 0
            star = equip.startLv or 0
        end
        if curQ >= quality and curS >= step then
            if curSt == 0 and curSt == star then
                curShowExp = curShowExp + comExp
                list[i]:SetHighlight(true)
                table.insert(self.selectList, list[i].data)
            elseif curSt == 1 and curSt >= star then--curSt == 1 and curSt == star then
                curShowExp = curShowExp + comExp
                list[i]:SetHighlight(true)
                table.insert(self.selectList, list[i].data)
            end
        end
    end
    self:ShowTComposeExp(curShowExp)
end

--显示吞噬将要获得的经验(点击)
function My:ShowComposeExp(isSelect,data)
    local showExp = self.showCompExp
    local equipId = data.type_id
    equipId = tostring(equipId)
    local comExp = 0
    local equipCfg = EquipBaseTemp[equipId]
    if equipCfg then
        comExp = equipCfg.petExp
    else
        equipCfg = ItemData[equipId]
        if equipCfg and equipCfg.uFxArg then
            local count = PropMgr.TypeIdByNum(equipId)
            comExp = equipCfg.uFxArg[1] * count
        end
    end

    -- local equipCfg = ItemData[equipId]
    -- local comExp = equipCfg.uFxArg[1]
    local rate = self.addRate
    if rate == nil then
        rate = 0
    end
    local add = comExp * (1+rate)
    add = math.ceil(add)
    if isSelect then
        showExp = showExp + add
    else
        showExp = showExp - add
    end
    self.showCompExp = showExp
    -- if self.showCompExp <= 0 then
    --     self.showCompExp = 0
    -- end
    self.expLab.text = self.showCompExp
    self:ShowSlidInfo()
end

--显示吞噬将要获得的经验(选中)
function My:ShowTComposeExp(curShowExp)
    if curShowExp == 0 then
        self.expLab.text = self.showCompExp
        self:ShowSlidInfo()
        return
    end
    local rate = self.addRate
    if rate == nil then
        rate = 0
    end
    local add = curShowExp * (1+rate)
    add = math.ceil(add)
    self.showCompExp = add + self.showCompExp
    self.expLab.text = self.showCompExp
    self:ShowSlidInfo()
end

--经验条显示
function My:ShowSlidInfo()
    local limit = GlobalTemp["149"].Value2[1]
    local curExp = self.showCompExp
    local value = curExp / limit
    local num = math.floor(value)
    local expLab = string.format("%s/%s",curExp,limit)
    local numLab = string.format("%s",num)
    self.slidLab.text = expLab
    self.slidSp.fillAmountValue = value
    self.propNum.text = numLab
end

--分解返回
function My:OnComposeInfo()

end

--vip加成描述
function My:ShowVipDes()
    local vipLv = VIPMgr.vipLv
    if vipLv == nil or vipLv <= 0 then
        self.vipDesLab.text = ""
		return
	end
	local vipCfg = VIPLv[vipLv+1]
	local vipDes = ""
	local addRate = 0
	if self.vipDesLab and vipCfg.arg18 then
		addRate = vipCfg.arg18/10000
        -- vipDes = string.format("[ee9a9e]V%s吞噬经验加成[-][67cc67]+%s%s[-]",vipLv,vipCfg.arg18/100,"%")
        vipDes = string.format("V%s吞噬经验加成+%s%s",vipLv,vipCfg.arg18/100,"%")
	end
	self.addRate = addRate
	self.vipDesLab.text = vipDes
end

--装备刷新
function My:RefreshBag()
    self:ClearSelectData()
    self:ShowData()
    self:ShowSlidInfo()
end

--品质筛选
function My:OnQuaSelect()
    local curQ = self:GetIndex(self.Quality, self.quality.value)
    self.curQuality = self.RealQuality[curQ]
    Players.SetInt("IntQ", curQ)
    self:SelectItem()
end

--等阶筛选
function My:OnStepSelect()
    local curS = self:GetIndex(self.Step, self.step.value)
    self.curStep = self.RealStep[curS]
    Players.SetInt("IntS", curS)
    self:SelectItem()
end

function My:OnStarSelect()
    if self.star.value == true then
        self.curStar = 1
    else
        self.curStar = 0
    end
    Players.SetInt("IntStar", self.curStar)
    self:SelectItem()
end

function My:UpdatePopVal(quality, step, star)
    quality = quality or #self.Quality
    step = step or #self.Step

    if Players.HasKey("IntQ") then
        quality = Players.GetInt("IntQ")
    end

    if Players.HasKey("IntS") then
		step = Players.GetInt("IntS")
    end

    self.quality.value = self.Quality[quality]
    self.step.value = self.Step[step]
    local indexQ = self:GetIndex(self.Quality, self.labQua.text)
    self.curQuality = self:SwitchQ(indexQ)
    local indexS = self:GetIndex(self.Step, self.labStep.text)
    self.curStep = self:SwitchS(indexS)

    if Players.HasKey("IntStar") then
        local starVal = Players.GetInt("IntStar")
        if starVal == 1 then
            self.star.value = true
        else
            self.star.value = false
        end
        self.curStar = starVal
    end
end

function My:SwitchQ(index)
    local curQ = self.RealQuality[index]
    return curQ
end

function My:SwitchS(index)
    local curS = self.RealStep[index]
    return curS
end

function My:GetIndex(list, val)
    local len = #list
    for i=1,len do
        if list[i] == val then
            index = i
            break
        end
    end
    return index
end

--点击吞噬
function My:OnComposeBtn()
    local list = self.selectList
    local len = #list
    if len == 0 then
        UITip.Log("请选择吞噬装备")
        return
    end
    PetMgr:ReqPetLevelUp(list)
end

function My:CloseCustom()

end

function My:DisposeCustom()
    -- if self.itemPropObj then
    --     self.itemPropObj:DestroyGo()
    --     ObjPool.Add(self.itemPropObj)
    --     self.itemPropObj = nil
    -- end
    self:UnLoadProTex()
    self:SetEvent("Remove")
    self:ClearSelectData()
    self.curQuality = 0
    self.curStep = 0
    self.curStar = 0
    self.showCompExp = 0
    self.index = 1
    TableTool.ClearListToPool(self.cellList)
end

return My