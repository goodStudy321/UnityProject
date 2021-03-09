UITransApp = UIBase:New{Name = "UITransApp"}
local My = UITransApp
My.prop = require("UI/UITransApp/UITransAppProp")
My.skill = require("UI/UITransApp/UITransAppSkill")
My.skiTip = require("UI/UITransApp/UITransAppSkilTip")
require("UI/UITransApp/UIListTransModItem")
local TMIT = UIListTransModItem

My.OpenIndex = 1
My.index = nil
My.db = nil
My.QPropId = 0
My.CurRedId = 0

function My:InitCustom()
    local root = self.root
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetBtnClick
    local TFC = TransTool.FindChild

    self.AppTog = CG(UIToggle,root,"TogGrid/AppTog",des)
    self.appRedG = TFC(root,"TogGrid/AppTog/action",des)
    self.fightLab = CG(UILabel,root,"fightLab",des)
    self.curNameLab = CG(UILabel,root,"curName/lab",des)
    self.curStepLab = CG(UILabel,root,"curName/lvLab",des)
    self.tranLbl = CG(UILabel,root,"changeBtn/lbl",des)
    self.propNumLab = CG(UILabel,root,"prop/propNumLab",des)
    self.btnLab = CG(UILabel,root,"Btn/lab",des)
    self.expLab = CG(UILabel,root,"propIcons/slid/exp",des)
    self.expSlide = CG(UISprite,root,"propIcons/slid/bg/Sprite")
    self.btnRed = TFC(root,"Btn/red",des)
    self.changBox = CG(BoxCollider, root, "changeBtn", des)
    self.desLab = TFC(root,"deslab",des)

    self.loadLabR = TFC(root, "loadLab", des)
    self.loadLabR:SetActive(false)
    self.loadLabBox = CG(BoxCollider, root, "loadLab", des)
    UITool.SetLsnrSelf(self.loadLabBox, self.OnLoadClick, self)

    self.btnGbj = TFC(root,"Btn",des)
    self.fullLabGbj = TFC(root,"fullLab",des)
    
    self.prop.root = TF(root,"props",des)
    self.prop:Init()
    
    local skill = TF(root,"skill",des)
    self.skill = UITransAppSkill:New()
    self.skill:Init(skill)
    
    self.prop = UITransAppProp:New()
    self.prop.root = TF(root, "props", des)
    self.prop:Init()
    
    local skillTipGbj = TF(root,"skiTip",des)
    self.skiTip = UITransAppSkilTip:New()
    self.skiTip:Init(skillTipGbj)

    self.modRoot = TF(root,"modelRoot",des)
    self.uiTbl = CG(UIGrid,root,"mods/Grid",des)
    self.item = TF(root,"mods/Grid/item",des)
    self.item.gameObject:SetActive(false)
    self.actSp = TF(root,"actSp",des)
    self.propGbj = TFC(root,"prop",des)

    self.ItemTabGbj = {}
	self.ItemTabObj = {}
    self.propIcons = TFC(root,"propIcons",des)
    self.icon1 = TFC(root, "propIcons/icon1",des)
    self.icon2 = TFC(root, "propIcons/icon2",des)
    self.ItemTabGbj = {self.icon1,self.icon2}
    for i = 1,#self.ItemTabGbj do
		local cell = self.ItemTabGbj[i]
		UIEvent.Get(cell.gameObject).onClick = function (gameObject) self:SwitchItem(gameObject); end
	end

    self.itDic = {}

    self.itemPropObj = nil
    self.itemPropObj = ObjPool.Get(UIItemCell)
    self.itemPropObj:InitLoadPool(self.propGbj.transform,0.9)

    self.getSkillList = {}
    self.equipBtn = TFC(root,"changeBtn",des)
    self.alFlag = TFC(root,"alFlag",des)

    self.tog = CG(UIToggle, root,"propIcons/coin/tog", name)
    self.togDes = CG(UILabel, root,"propIcons/coin/tog/des", name)
    self.togDes.text = "不足时自动消耗绑元(绑元不足消耗元宝)"
    self.togLabSp = CG(UISprite, root,"propIcons/coin/const/sp", des)
    self.togLabSp.spriteName = "money_03"
    self.costNumLab = CG(UILabel,root,"propIcons/coin/const/num",name)
    UITool.SetLsnrSelf(self.tog.gameObject, self.AutoCost, self, des, false)

    USBC(root, "changeBtn", des, self.ReqChange, self)
    USBC(root,"CloseBtn", des, self.CloseBtns, self)
    USBC(root, "Btn", des, self.OnRefine, self)
    self.StarList = {}
	for i = 1,10 do
		local start = CG(UISprite,root,"stars/start"..i,des,false)
		table.insert(self.StarList,start)
    end
    self.isQuickUse = false
    self:Reset()
    self.AppTog.value = true
    self:SetConsume()
    self:ShowAutoCost()
    -- self:RespRed()
    self:AddEvent()
end

--是否勾选自动消耗
function My:AutoCost()
	local val = self.tog.value
	local index = 0
	if val == true then
        index = 1
    else
        index = 0
    end
	PlayerPrefs.SetInt("TransAutoCost", index)
	self.isAutoCost = val
	self:ShowCostNum()
end

function My:ShowAutoCost()
	local isVal = false
	if PlayerPrefs.HasKey("TransAutoCost") then
        local val = PlayerPrefs.GetInt("TransAutoCost")
        if val == 1 then
            isVal = true
        else
            isVal = false
		end
	end
	self.tog.value = isVal
	self.isAutoCost = isVal
	self:ShowCostNum()
end

--显示消耗元宝数量
function My:ShowCostNum()
	local isAuto = self.isAutoCost
	local total, ids = 0, self.db.iItemsIds
    local GetNum = ItemTool.GetNum
    local propExp = 0
    for i, v in ipairs(ids) do
		local num = GetNum(v)
		total = total + num
		local cfg = ItemData[tostring(v)]
		local getExp = cfg.uFxArg[1]
		propExp = (num * getExp) + propExp
	end

    -- total = total + GetNum(ids)
	-- if total > 0 then
	-- 	isAuto = false
	-- end
	local num = 0
    local needProp = 0
	if isAuto == true then
		local cfg = ItemData[tostring(ids[1])]
        local getExp = cfg.uFxArg[1]
        local info = self.db.info
        local curExp = info.exp
        local limit = info.sCfg.costSoul
        local needExp = limit - (curExp + propExp)
        if needExp > 0 then
            needProp = math.ceil(needExp/getExp)
            local needCost = StoreData[tostring(self.StoreId)].curPrice --价格
            num = needCost * needProp
        else
            num = 0
        end
	else
		num = 0
	end
	self.costPNum = needProp
	self.costNumLab.text = num
end


--index：1：坐骑   2：伙伴
function My.OpenTransApp(index,qPropId)
    if index == 1 then
        My.db = MountAppMgr
    elseif index == 2 then
        My.db = PetAppMgr
    end
    local pId = qPropId
    if pId == nil or pId <= 0 then
        pId = 0
    end
    My.QPropId = pId
    UIMgr.Open(UITransApp.Name)
end

function My:OnLoadClick()
    self:Close()
    UIMgr.Open("UIDownload")
end

function My:AddEvent()
    self:SetLsnr("Add")
    PropMgr.eUpdate:Add(self.SetItemNum, self)
end

function My:RemoveEvent()
    self:SetLsnr("Remove")
    PropMgr.eUpdate:Remove(self.SetItemNum, self)
end

function My:SetLsnr(fn)
    local db = self.db
    -- db.eStep[fn](db.eStep, self.AdvStep, self)
    -- db.eRespUpg[fn](db.eRespUpg, self.RespUpg, self)
    db.eRespRefine[fn](db.eRespRefine, self.RespRefine, self)
    db.eRespActive[fn](db.eRespActive, self.RespActive, self)
    db.eRespChange[fn](db.eRespChange, self.RespChange, self)
    db.eRespRed[fn](db.eRespRed, self.RespRed, self)
end

function My:RespRed()
    if self.db == nil then return end
    local list = self.db.SkinRedTab
    local itDic = self.itDic
    local isRed = false
    for k,v in pairs(itDic) do
        if list[k] ~= nil then
            if self.CurRedId == 0 then
                self.CurRedId = k
            end
            isRed = true
            v:IsShowAction(true)
        else
            isRed = false
            v:IsShowAction(false)
        end
    end
    -- local isShowRed = self.db.isTransRed
    -- self.btnRed:SetActive(isRed)
    self:SwitchRed()
end

function My:SwitchRed()
    local basdId = self.curSeBid
    local skinRedTab = self.db.SkinRedTab
    local itDic = self.itDic
    if skinRedTab[basdId] ~= nil then
        self.btnRed:SetActive(true)
        -- itDic[basdId]:IsShowAction(true)
    else
        self.btnRed:SetActive(false)
        -- itDic[basdId]:IsShowAction(false)
    end
end

--设置消耗
function My:SetConsume()
    local ids = {}
    local items, it = self.ItemTabObj, nil
    ids = self.db.iItemsIds
    local GetNum = ItemTool.GetNum
    if #self.ItemTabObj <= 0 then
        for i = 1,#self.ItemTabGbj do
            local cellGbj = self.ItemTabGbj[i]
            local it = ObjPool.Get(UIItem)
            local id = ids[i]
            it:Init(cellGbj.transform)
            it.root.name = id
            it:RefreshByID(id)
            self.ItemTabObj[id] = it
        end
    else
        for i = 1,#ids do
            local id = ids[i]
            it = items[i]
            it:RefreshByID(id)
        end
    end
  
    local totalExp = 0
	local isCanLv = false
	for i,v in pairs(ids) do
		local num1 = GetNum(v)
		num1 = num1 or 0
		if num1 > 0 then
		  local cfg = ItemData[tostring(v)]
		  local exp = cfg.uFxArg[1] * num1
		  totalExp = totalExp + exp
		end
	end

    local info = self.db.info
    local curExp = info.exp
    local costExp = info.sCfg.costSoul
    local needExp = costExp - curExp
    if needExp and totalExp >= needExp then
		isCanLv = true
	end
    self.isCanLv = isCanLv

    local firstId = ids[1]
    local secondId = ids[2]
    self.PropId = firstId
    self.StoreId = StoreMgr.GetStoreId(5,firstId)
    local secondNum = GetNum(secondId)
    for i = 1,#ids do
        local id = ids[i]
        num = GetNum(id)
        if self.db.curSelectId == secondId and secondNum > 0 then
            cell = self.ItemTabObj[secondId]
            self:SwitchItem(cell.root)
            self.db.curSelectId = secondId
            return
        elseif num > 0 then
            cell = self.ItemTabObj[id]
            self:SwitchItem(cell.root)
            self.db.curSelectId = id
            return
        elseif self.curCell == nil then
            cell = self.ItemTabObj[firstId]
            self:SwitchItem(cell.root)
            self.db.curSelectId = firstId
        elseif secondNum == 0 then
            self.ItemTabObj[secondId]:SetSelect(false)
        end
    end
end

function My:SwitchItem(it)
	local id = tonumber(it.name)
    self.db.curSelectId = id
    local cellSelf = self.ItemTabObj[id]
    if self.curCell == cellSelf then
        PropTip.pos = self.curCell.root.transform.position
		PropTip.width = self.curCell.qtSp.width
        UIMgr.Open("PropTip", self.ShowTip, self)
        return
    end
    if self.curCell then
        self.curCell:SetSelect(false)
    end
    cellSelf:SetSelect(true)
    self.curCell = cellSelf
end

function My:ShowTip(name)
	local ui = UIMgr.Get(name)
	local id = self.curCell.cfg.id
	ui:UpData(id)
end

function My:ReItemsNum()
end

--精炼按钮事件
function My:OnRefine()
    self:ReqRefine()
end

--请求自动精炼
function My:ReqRefine()
    self.IsAutoClick = nil
    local lock = self.db.info.lock 
    local propid = self.db.info.sCfg.propId
    local bid = self.db.info.bCfg.id
    local stars = self.db.info.sCfg.stars

    if stars >= 10 then
        -- iTrace.Error("GS"," 点击  进阶")
        if not self:RefineCond() then return end
        self.db:ReqAcive(bid)
        return
    end
    if lock then
        -- iTrace.Error("GS"," 点击  激活")
        if not self:RefineCond() then return end
        self.db:ReqAcive(bid)
        return
    else
        -- iTrace.Error("GS"," 点击  升级")
        -- UIEvent.Get(self.btnGbj.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)

        self:OnPress()

        -- local num = PropMgr.TypeIdByNum(self.db.curSelectId)
        -- if num <= 0 then
        --     if self.db.sysId == 1 then
        --         UIMgr.Open(UIGetWay.Name, self.OpenMGetWayCb ,self)
        --     elseif self.db.sysId == 2 then
        --         UIMgr.Open(UIGetWay.Name, self.OpenPetGetWayCb ,self)
        --     end
        --     return
        -- end
        -- local uid = PropMgr.TypeIdById(self.db.curSelectId)
        -- self.db:ReqStep(bid,uid)
    end
end

function My:OnPressCell(go, isPress)
    local lock = self.db.info.lock 
    local stars = self.db.info.sCfg.stars
    if lock == true or stars >= 10 then
        self.IsAutoClick = nil
        return
    end
    if not go then
		return
	end
	if isPress== true then
		self.IsAutoClick = Time.realtimeSinceStartup
	else
		self.IsAutoClick = nil
	end
end

function My:Update()
    -- if self.IsAutoClick == nil then
    --     return
    -- end
	-- if self.IsAutoClick then
	-- 	if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
	-- 		self.IsAutoClick = Time.realtimeSinceStartup
	-- 		self:OnPress()
	-- 	end
	-- end
end

--长按升级  to server
function My:OnPress()

    local total, ids = 0, self.db.iItemsIds
	local GetNum = ItemTool.GetNum
  	for i, v in ipairs(ids) do
    	total = total + GetNum(v)
  	end

    local isAutoC = self.isAutoCost
    local pNum = self.costPNum
    local id = self.PropId
    local pStorId = self.StoreId
    local bid = self.curSeBid

    if total < 1 or self.isCanLv == false then
        if isAutoC == false then
            if total >= 1 then
				for i, v in ipairs(ids) do
					local num = GetNum(v)
                    if num > 0 then
                        self.db:ReqStep(bid,v,num)
					end
				end
				return
			end
			local selectId = self.db.info.bCfg.id
			-- local itID = self.PropId
			local itID = self.db.curSelectId  
			local isSkin = false
			local sysId = self.db.sysId
			GetWayFunc.AdvGetWay(UITransApp.Name,sysId,itID,isSkin,selectId)
			return 
		elseif isAutoC == true then
			-- if not uid then
			-- 	iTrace.eError("GS",string.format("招不到id%s的uid",id))
			-- 	return 
			-- end
			-- StoreMgr.QuickBuy(pStorId,pNum,true)
			local isEnough=StoreMgr.QuickBuy(pStorId,pNum,false)
            if isEnough then
                for i, v in ipairs(ids) do
                    local num = GetNum(v)
                    if v == id then
                      num = num + pNum
                    end
                    if num > 0 then
                        self.db:ReqStep(bid,v,num)
                    end
                end
				-- self.db:ReqStep(bid,id,pNum)
			end
			return
		end
    end
	for i, v in ipairs(ids) do
		local num = GetNum(v)
        if num > 0 then
            -- local uid = PropMgr.TypeIdById(v)
            self.db:ReqStep(bid,v,num) 
			-- PropMgr.ReqUse(v, num, 1)
		end
  	end

    
    -- local bid = self.db.info.bCfg.id
    -- local id = self.PropId
    -- local num = PropMgr.TypeIdByNum(pId)
    -- if num <= 0 then
    --     if self.db.sysId == 1 then
    --         UIMgr.Open(UIGetWay.Name, self.OpenMGetWayCb ,self)
    --     elseif self.db.sysId == 2 then
    --         UIMgr.Open(UIGetWay.Name, self.OpenPetGetWayCb ,self)
    --     end
    --     self.IsAutoClick = nil
    --     return
    -- end
    -- local uid = PropMgr.TypeIdById(self.db.curSelectId)
    -- self.db:ReqStep(bid,uid)
end

--获取坐骑途径界面回调
function My:OpenMGetWayCb(name)
	local ui = UIMgr.Get(name)
  ui:SetPos(Vector3(85,-110,0))
	local petGetWay = AdvGetWayCfg[1].wayDic
	local len = #petGetWay
	for i = 1,len do
		local wayName = petGetWay[i].v
		ui:CreateCell(wayName, self.OnClickMGetWayItem, self)
	end
end

function My:OnClickMGetWayItem(name)
	if name == "商城" then
		JumpMgr:InitJump(UITransApp.Name,1)
        self.propid = 30301
        self:OpenShop()
	end
end

--获取宠物途径界面回调
function My:OpenPetGetWayCb(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(85,-110,0))
	local petGetWay = AdvGetWayCfg[3].wayDic
	local len = #petGetWay
	for i = 1,len do
		local wayName = petGetWay[i].v
		ui:CreateCell(wayName, self.OnClickPetGetWayItem, self)
	end
end

function My:OnClickPetGetWayItem(name)
	if name == "伙伴副本" then
		local other,isOpen = CopyMgr:GetCurCopy("7")
        if isOpen then
            JumpMgr:InitJump(UITransApp.Name,2)
            UICopy:Show(CopyType.SingleTD)
        else
            UITip.Error("系统未开启")
        end
	elseif name == "商城" then
		JumpMgr:InitJump(UITransApp.Name,2)
        self.propid = 30361
        self:OpenShop()
	end
end

--打开坐骑商城界面
function My:OpenShop()
    local storeId = StoreMgr.GetStoreId(4,self.propid)
    StoreMgr.selectId = storeId
    StoreMgr.OpenStore(4)
  end

--精炼条件
function My:RefineCond()
    self.IsAutoClick = nil
    local sysId = self.db.sysId
    local itID = self.curPropId
    local propNum = PropMgr.TypeIdByNum(itID)
    local needNum = self.db.info.sCfg.propNum
    local nNum = needNum - propNum
    res = ItemTool.NumCond(itID, nNum,false)
    if res == false then
        GetWayFunc.AdvGetWay(UITransApp.Name,sysId,itID)
    end
    return res
end


--清理条目字典
function My:ClearItDic()
    local itDic, root = self.itDic, self.root
    local OA, tran = ObjPool.Add, nil
    for k, v in pairs(itDic) do
      tran = v.root.transform
      tran.name = "none"
      tran.parent = root
      tran.gameObject:SetActive(false)
      itDic[k] = nil
      OA(v)
    end
end

--重设条目字典
function My:Reset()
    local itMod, db, it = self.item, self.db, nil
    local dic, p = db.dic, self.root
    local info, go, c = nil, nil, nil
    local uiTblTran = self.uiTbl.transform
    local itDic, name, k = self.itDic, nil, nil
    TransTool.RenameChildren(uiTblTran)
    for i, v in pairs(db.iCfg) do
        name = v.name
        k = v.id
        info = dic[k]
        if info then
            c = p:Find("none")
            if c then
            go = c.gameObject
            else
            go = Instantiate(itMod)
            c = go.transform
            end
            go.name = k
            it = ObjPool.Get(TMIT)
            it.info = info
            it.cntr = self
            itDic[k] = it
            go.gameObject:SetActive(true)
            it:Init(c)
            TransTool.AddChild(uiTblTran, c)
            -- it:InitData(v)
        end
    end
    self:RespRed()
    local ck = self.db.iCfg[1].id
    local qPropId = self.QPropId
    if qPropId > 0 then
        if qPropId > 100000 then
            ck = qPropId/100
        else
            ck = qPropId
        end
    elseif self.CurRedId > 0 then
        ck = self.CurRedId
    end
    self:SwitchIt(self.itDic[ck])
    self.QPropId = 0
    self.CurRedId = 0
end

function My:GetPropCfg()
    local info,cCfg,nCfg = self.db.info,nil,nil
    if info.lock then
        nCfg = info.sCfg
    else
        cCfg = info.sCfg
        nCfg = info:GetNextCfg()
    end
    return cCfg,nCfg
end

--激活星级
function My:ActiveStars()
    local max = 10
    local info = self.db.info
    local st = info.sCfg.stars
    if info.lock then
        for i = 1, max do
            local go = self.StarList[i]
            if info.lock then
                go.spriteName = "star_dark"
            end
        end
    else
        for i = 1, max do
            local go = self.StarList[i]
            if st < i then
                go.spriteName = "star_dark"
            else
                go.spriteName = "star_light"
            end
        end
    end
end

--响应激活
function My:RespAct(id, unlock)
    if not unlock then return end
    local k = self.db.GetKey(id)
    local it = self.itDic[k]
    it:SetLock()
  end

--响应精炼
function My:RespRefine(id,unlock)
    local info = self.db.info
    self.prop:Refresh()
    self:SetFight()
    self:SetBtnDes(info.lock)
    local stars = info.sCfg.stars
    -- self.db.info.sCfg.stars
    self:ActiveStars()
    self:SetStep()
    -- local act = info.sCfg.propId > 0
    self:ShowDifProp(info.lock)
    self.curSCfg = info.sCfg
    self:SwitchRed()
    if stars >= 10 then
        self:InitPropCell(info.sCfg)
        self:ShowDifProp(true)
    end
    self:IsFullStep()
    local k = self.db.GetKey(id)
    local it = self.itDic[k]
    it:SetLock()
    -- self:SetConsume()
    self:ShowSlid(info.exp)
    if(unlock == true) then
        local id = AssetTool.GetSexModID(info.bCfg)
        UIShowGetCPM.OpenCPM(id)
    end
    self:ShowCostNum()
end

--响应激活
function My:RespActive(id,unlock)
    local info = self.db.info
    self.prop:Refresh()
    self:SetFight()
    self:SetBtnDes(info.lock)
    local stars = info.sCfg.stars
    -- self.db.info.sCfg.stars
    self:ActiveStars()
    self:SetStep()
    -- local act = info.sCfg.propId > 0
    self:ShowDifProp(info.lock)
    self:SetTranLbl()
    if stars >= 10 then
        -- self:InitPropCell(info.sCfg)
        self:ShowDifProp(true)
    end
    local k = self.db.GetKey(id)
    local it = self.itDic[k]
    it:SetLock()
    self.curSCfg = info.sCfg
    -- self:SetConsume()
    self:RefreshSkill()
    self:ShowSlid(info.exp)
    if(unlock == true) then
        local id = AssetTool.GetSexModID(info.bCfg)
        UIShowGetCPM.OpenCPM(id)
    end
end

--响应幻化
function My:RespChange(err)
    if err > 0 then return end
    self:SetTranLbl()
end


function My:ReqChange()
    local info = self.db.info
    if info.lock then
        UITip.Error("未解锁")
    elseif self:IsChange() == true then
        UITip.Error("已装备")
        return
    else
        local sysId = self.db.sysId
        local id = nil
        if sysId == 1 then --坐骑
            id = self.db.GetBID(info.sCfg.id)
        elseif sysId == 2 then --伙伴
            id = info.sCfg.id
        end
        -- local bid = self.db.GetBID(info.sCfg.id)
        -- bid = bid * 100
        self.db:ReqChange(id)
    end
end

--it:UIListModItem
function My:SwitchIt(it)
    self.IsAutoClick = nil
    if it == nil then return end
    local cur = self.cur
    if cur == it then return end
    self.cur = it
    if cur then cur:SetActive(false) end
    it:SetActive(true)
    self:Switch(it.info)
end


--切换条目信息
function My:Switch(info)
    local db = self.db
    info = info or db.info
    db.info = info
    local bCfg = info.bCfg
    local sCfg = info.sCfg
    self.curSCfg = sCfg
    local act = sCfg.propId > 0
    self:ShowDifProp(info.lock)
    if act == false then
        self:SetConsume()
        self:ShowCostNum()
    end
    -- self:RespRed()
    self.curSeBid = bCfg.id
    self:SwitchRed()
    self:SetName(bCfg.name)
    self:ResetProps()
    self:SetFight()
    self:SetTranLbl()
    self:RefreshSkill()
    self:InitPropCell(sCfg)
    -- self:ShowPropNum(sCfg)
    self:SetBtnDes(info.lock)
    self:ActiveStars()
    self:SetStep()
    self:ShowSlid(info.exp)
    local stars = info.sCfg.stars
    if stars >= 10 then
        self:ShowDifProp(true)
    end
    self:IsFullStep()
end

function My:ShowDifProp(isShowOne)
    self.propIcons:SetActive(not isShowOne)
    self.propGbj:SetActive(isShowOne)
end

--是否已经满阶
function My:IsFullStep()
    local info = self.db.info
    local sCfg = info.sCfg
    local costS = sCfg.costSoul
    local isFull = costS == 0 and true or false
    self.btnGbj:SetActive(not isFull)
    self.fullLabGbj:SetActive(isFull)
    local stars = info.sCfg.stars
    -- self.propGbj:SetActive(true)
    if isFull == true and stars >= 10 then
        self.propGbj:SetActive(false)
    end
end

function My:ShowSlid(value)
    local max = self.db.info.sCfg.costSoul
    if max == 0 then return end
    local slidVal = value/max
    local strVal = string.format("%s/%s",value,max)
    self.expSlide.fillAmount= slidVal
    self.expLab.text = strVal
end

function My:InitPropCell(sCfg)
    if sCfg.propId == 0 then
        return
    end
    local itemid = tostring(sCfg.propId)
    self.curPropId = sCfg.propId
    local propNum = PropMgr.TypeIdByNum(itemid)
    self.itemPropObj:UpData(itemid, propNum)
    self:SetItemNum()
end

function My:ShowPropNum(sCfg)
    if sCfg.propId == 0 then
        return
    end
    local sb = ObjPool.Get(StrBuffer)
    local itemid = tostring(sCfg.propId)
    local itemData = ItemData[itemid]
    local propName = itemData.name
    local own = PropMgr.TypeIdByNum(itemid)
    local need = sCfg.propNum
    -- if own < need then
    --     self.isCanRoProp = false
    -- elseif own >= need or need == 0 then
    --     self.isCanRoProp = true
    -- end
    local propC = (own < need and "[e83030]" or "[67cc67]")
    local desLabC = "[F39800FF]"
    sb:Apd(desLabC):Apd("消耗:"):Apd(propName):Apd("[-]")
    sb:Apd(propC):Apd(own):Apd("[-]"):Apd("/"):Apd(need)
    self.propNumLab.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:SetItemNum() 
    local propId = self.curPropId
    local propNum = PropMgr.TypeIdByNum(propId)
    self.itemPropObj:UpLab(propNum)
    self:ShowPropNum(self.curSCfg)
    self:SetConsume()
    self:ShowCostNum()
end

function My:ResetProps()
    local prop = self.prop
    prop.srcObj = self
    prop.GetCfg = self.GetPropCfg
    prop:SetNames(self.db.skinPropNames)
    prop:Refresh()
end

function My:IsChange()
    local db = self.db
    -- local bid = self.db.GetBID(db.info.sCfg.id)
    -- bid = bid * 100
    local systemId = db.sysId
    local id = nil
    if systemId == 1 then
        id = db.info.bCfg.id
    elseif systemId == 2 then
        id = db.info.sCfg.id
    end
    if db.chgID == id then return true end
    return false
end

--设置幻化标签
function My:SetTranLbl()
    local isShow = self:IsChange()
    local str = ((isShow == true) and "已装备" or "幻化")
    self:IsShowAlFlag(isShow)
    self.tranLbl.text = str
end

function My:IsShowAlFlag(isShow)
    self.equipBtn.gameObject:SetActive(not isShow)
    self.alFlag.gameObject:SetActive(isShow)
  end

function My:SetName(name)
    self.curNameLab.text = name
end

function My:SetStep()
    local st = self.db.info.sCfg.step
    local str = UIMisc.ToNum(st)
    local stepStr = string.format( "%s阶",str)
    self.curStepLab.text = stepStr
end

function My:SetFight()
    local cfg = self.db.info.sCfg
    local names = self.prop.names
    local ft = PropTool.GetFight(cfg, names)
    -- local ft = self.db:GetFight()
    self.fightLab.text = ft
end

function My:RefreshSkill()
    local skillsList = self.db.info.sCfgSkill.hSkillIds
    local sCfg = self.curSCfg
    if sCfg.hSkillIds then
        self.getSkillList = self:ReHaveSkill(sCfg.hSkillIds)
    end
    self.skill:Refresh(skillsList,self.GetLvSkiLock,self)
    self.skill:Open()
end

--判断技能是否解锁
--true :未解锁  false:解锁
function My:GetLvSkiLock(skillId)
    local lock = self.db.info.lock
    if lock then
        return true
    end
    if self.getSkillList[skillId] == nil then
        return true
    else
        return false
    end
    return true
end

--已经拥有的技能
function My:ReHaveSkill(skillList)
    local temp = {}
    for i = 1,#skillList do
        local skillId = skillList[i]
        if temp[skillId] == nil then
            temp[skillId] = skillId
        end
    end
    return temp
end

function My:SetBtnDes(lock)
    self.btnLab.text = self:GetDes(lock)
    self.actSp.gameObject:SetActive(lock)
end

function My:GetDes(lock)
    local stars = self.db.info.sCfg.stars
    self.desLab:SetActive(false)
    self.isQuickUse = false
    if stars >= 10 then
        return "进阶"
    elseif lock == true then
        return "激活"
    elseif lock == false then
        self.desLab:SetActive(false)
        self.isQuickUse = true
        return "一键升级"
    end
    -- self.curPropId = self.db.info.sCfg.propId
end

function My:IsShowAssTip(isShowTip)
    self:Lock(false)
    local box = self.changBox
    box.enabled = not isShowTip
    self.loadLabR:SetActive(isShowTip)
end


--清除宠物升级消耗texture
function My:ClearIcon()
	-- if self.ItemTabObj then
	--   for k,v in pairs(self.ItemTabObj) do
	-- 	v:ClearIcon()
	--   end
	-- end
end

function My:ItemToPool()
	local len = #self.ItemTabObj
	while len > 0 do
	  local item = self.ItemTabObj[len]
      if item then
        item:ClearIcon()
        table.remove(self.ItemTabObj, len)
		ObjPool.Add(item)
	  end
	  len = #self.ItemTabObj
	end
end

function My:ItemGbjD()
	local len = #self.ItemTabGbj
	while len > 0 do
	  local item = self.ItemTabGbj[len]
	  if item then
		table.remove(self.ItemTabGbj, len)
	  end
	  len = #self.ItemTabGbj
	end
end

function My:CloseBtns()
    self:Close()
    JumpMgr.eOpenJump()
end

-- function My:CloseCustom()

-- end

function My:DisposeCustom()
    if self.itemPropObj then 
        self.itemPropObj:DestroyGo() 
        ObjPool.Add(self.itemPropObj) 
        self.itemPropObj=nil 
    end
    self.QPropId = 0
    self.CurRedId = 0
    self.IsAutoClick = nil
    self:ClearIcon()
    self:ItemToPool()
	self:ItemGbjD()
    self:RemoveEvent()
    self.db = nil
    self.cur = nil
    self.curSCfg = nil
    self.curPropId = nil
    self.curCell = nil
    self.isQuickUse = false
    self.skiTip:Dispose()
    self.prop:Dispose()
    self.skill:Dispose()
    self:ClearItDic()
    TableTool.ClearDic(self.getSkillList)
end

return My