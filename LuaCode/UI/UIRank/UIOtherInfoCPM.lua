
UIOtherInfoCPM = UIBase:New{Name = "UIOtherInfoCPM"}
local My = UIOtherInfoCPM

local cellDic = {}
local bgList = {}
local btns = {"Strengthen"}

function My:InitCustom()
    local trans = self.root
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    local name = self.Name
    self.NameLab = CG(UILabel, trans, "WearsShow/NameLab", name, false)
    self.LvLab = CG(UILabel, trans, "WearsShow/LvLab", name, false)
    self.LvBG = CG(UISprite, trans, "WearsShow/LvLab/Sprite", name, false)
    self.FamilyName = CG(UILabel, trans, "WearsShow/FamilyName", name, false)
    self.Charm = CG(UILabel, trans, "WearsShow/Charm", name, false)
    self.Vip = CG(UISprite, trans, "WearsShow/Vip", name, false)
    self.FightLab = CG(UILabel, trans, "WearsShow/FightLab", name, false)
    self.grid = CG(UIGrid, trans, "WearsShow/Grid", name, false)
    self.Model = TF(trans, "WearsShow/Model").transform
    self.bgPre = TF(self.grid.transform, "F")
    --self.title = TF(trans, "WearsShow/title").transform
    self.cateDO = TF(trans,"WearsShow/des/cateDO")
    self.cateDT = TF(trans,"WearsShow/des/cateDT")
    self.cateTO = TF(trans,"WearsShow/des/cateTO")
    self.cateTT = TF(trans,"WearsShow/des/cateTT")
    UITool.SetBtnClick(trans, "WearsShow/CloseBtn", name, self.OnClose, self)
	self.RebirthLv = GlobalTemp["91"]
    self.RoleLv = GlobalTemp["90"]
    self.skin = ObjPool.Get(RoleSkin)
    self.skin.eLoadModelCB:Add(self.SetModel, self)
    self:InitCell()
    self:UpdateData()
    self:SetLsnr("Add")
end

function My:OnClose( ... )
    self:Close()
    JumpMgr.eOpenJump()
end

function My:SetLsnr(key)
    UserMgr.eUpdateData[key](UserMgr.eUpdateData, self.UpdateData, self)
end

-- function My:CloseUI()
--     UIMgr.Close(self.Name)
--     local ui = UIMgr.Get(UIRank.Name)
--     if (ui) then
--         ui.modRoot:SetActive(true)
--     end
--     JumpMgr.eOpenJump()
-- end

function My:InitCell()
    self:CreateCell(12)
	self:CreateCell(10)
	self:CreateCell(9)
	self:CreateCell(8)
	self:CreateCell(7)
	self:CreateCell(1)
	self:CreateCell(11)
	self:CreateCell(3)
	self:CreateCell(4)
	self:CreateCell(2)
	self:CreateCell(5)
    self:CreateCell(6)
    
    self.grid:Reposition()
end

function My:CreateCell(part)
    local cell = ObjPool.Get(UIItemCell)
    cell:InitLoadPool(self.grid.transform)
    cellDic[tostring(part)] = cell

    self:CreateBg(cell.trans)
end

function My:CreateBg(parent)
    local bg = GameObject.Instantiate(self.bgPre)
    bg.transform.parent = parent
    bg:SetActive(true)
    bg.transform.localScale = Vector3.one
    bg.transform.localPosition = Vector3.New(-40.5, 40.8, 0)
    bgList[#bgList+1] = bg
end

function My:UpdateData()
    local info = UserMgr.OtherInfo
    self.info = info
    if not info then return end
    self:SetNameLab(info.name)
    self:SetLvLab(info.lv)
    self:SetFamilyName(info)
    self:SetCharm(info)
    self:SetVip(info.vip)
    self:SetFightLab(info.power)
    self:UpdateEquip(info.equips)
    self:CreateSkin((info.cate * 10 + info.sex) * 1000 + info.lv, info.skins, info.sex)
    self:ShowDes(info.cate)
    self:GuardUp(info.rGuard)
    self:BigGuardUp(info.lGuard,info.lv)
    --self:UpdateTitle(info.title)
end

function My:SetNameLab(name)
    if self.NameLab then
        self.NameLab.text = name
    end
end

function My:SetLvLab(lv)
    if self.LvLab then
        self.LvLab.text = UserMgr:GetChangeLv(lv, false)
    end
    if self.LvBG then
        local name = "ty_19"
        if UserMgr:IsGod(lv) then
            name = "ty_19A"
        end
        self.LvBG.spriteName = name
    end
end

function My:SetFamilyName(info)
    local Id = tonumber(info.familyId)
    local value = Id ~= 0
    if self.FamilyName then
       -- self.FamilyName.gameObject:SetActive(value)
       local name = "无"
        if value == true then
            name = info.familyName
        end
        self.FamilyName.text = "【"..name.."】"
    end
end

function My:SetCharm(info)
   if self.Charm then
        self.Charm.text = tostring(info.charm)
   end
end

function My:SetVip(vip)
    local value = vip ~= 0
    if self.Vip then
        self.Vip.gameObject:SetActive(value)
        if value == true then
            self.Vip.spriteName = "vip"..vip
        end
    end
end

function My:SetFightLab(power)
    if self.FightLab then
        self.FightLab.text = power
    end
end

function My:UpdateEquip(list)
    if not list then return end
    local len = #list
    for i=1,len do
        local equip = list[i]
        local temp = EquipBaseTemp[tostring(equip.type_id)]
        if temp then
            self:EquipLoad(equip, tostring(temp.wearParts))
        end
    end
end


-- 显示人物说明
function My:ShowDes(type)
    if type == 2 then
        self.cateDO:SetActive(true)
        self.cateTO:SetActive(true)
    else
        self.cateDT:SetActive(true)
        self.cateTT:SetActive(true)
    end
end

function My:EquipLoad(tb, part)
    local cell = cellDic[part]
    local item = ItemData[tostring(tb.type_id)]
    local equip = EquipBaseTemp[tostring(tb.type_id)]
    cell:TipData(tb, nil, btns)
    cell:UpBind(tb.bind)
    cell:UpWork("",self.info.cate)
end

function My:CreateSkin(id, skins, sex)
    self.skin:DestroyModel()
    self.skin:Create(self.Model, id, skins, sex)
end

function My:SetModel(go)
    go.transform.localRotation = Quaternion.Euler(0,0,0)
end


--守护
function My:GuardUp(guard)
	if guard.type_id==0 then return end
	local cell=cellDic["11"]
	cell.isGuard=true
	cell:TipData(guard)
	--bgDic["11"]:SetActive(false)
	--self.addDic["11"]:SetActive(false)
end

-- --守护过期
-- function My:OverTime()
-- 	local cell=cellDic["11"]
-- 	cell:Clean()
-- 	bgDic["11"]:SetActive(true)
-- 	self.addDic["11"]:SetActive(true)
-- end

--心结
function My:BigGuardUp(guard,lv)
	local cell=cellDic["12"]
	local click = TransTool.FindChild(cell.trans,"Click")
    cell:Lock(0.001)
    local id = guard.type_id
	--bgDic["12"]:SetActive(false)
	--local tip = TransTool.FindChild(cell.trans,"tip")
	--tip:SetActive(false)
	if id>0 then --已装备
		--self.addDic["12"]:SetActive(false)		
		cell.isGuard=true
		cell:TipData(guard)
		--self.bigTipTp=1
	elseif id==0 then --已开启未装备
		--bgDic["12"]:SetActive(true)
		--self.addDic["12"]:SetActive(true)	
		--self.bigTipTp=2
	elseif id==-1 and lv>=300 then --可开启
		--tip:SetActive(true)
		cell:IconUp(false)
		--self.bigTipTp=3
	else --未解锁
		cell:Lock(1)	
		--self.bigTipTp=4			
	end

	-- if self.bigTipTp>=3 then 		
	-- 	UITool.SetLsnrSelf(click,self.OnOpenTip,self,self.Name)	
	-- end
	--click:SetActive(self.bigTipTp>=3)
end

-- function My:OpenCustom()
--     self:InitCell()
--     self:UpdateData()
-- end

-- function My:CloseCustom()
--     self:ClearItem()
--     self:CleanData()
-- end

function My:ClearItem()
    for k,v in pairs(cellDic) do
        if k or v then
            v:DestroyGo()
            ObjPool.Add(v)
            cellDic[k] = nil
        end
    end
end

function My:CleanData()
    -- while self.Model.childCount>0 do
    --     local count = self.Model.childCount
    --     local go = self.Model:GetChild(count-1).gameObject
    --     go.transform.parent = nil
    --     GameObject.Destroy(go)
    -- end
    while #bgList>0 do
        local go = bgList[#bgList]
        GameObject.Destroy(go)
        bgList[#bgList] = nil
    end
end

function My:DisposeCustom()
    self:SetLsnr("Remove")
    self:ClearItem()
    self:CleanData()
    self.skin.eLoadModelCB:Remove(self.SetModel, self)
    ObjPool.Add(self.skin)
    self.skin = nil
end

return My