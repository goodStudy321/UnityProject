--[[
    闭关收益界面
]]
UIRetreatAward = UIBase:New{Name = "UIRetreatAward"}
local M = UIRetreatAward
local mathToStr = math.NumToStrCtr

function M:InitCustom()
    local C = ComTool.Get
    local T = TransTool.FindChild
    local tip = self.Name
    local trans = self.root

    local infoObj = T(trans,"Info",tip).transform
    self.offTimeLb = C(UILabel,infoObj,"OffTime",tip)
    self.expLb = C(UILabel,infoObj,"ExpAward",tip)
    self.iconLb = C(UILabel,infoObj,"IconAward",tip)
    self.numLb = C(UILabel,infoObj,"NumLb",tip)
    self.spendLb = C(UILabel,infoObj,"HLb",tip)

    -- 格子
    self.girdTrans = T(trans,"EquipShow/GetEquip/Grid",tip).transform
    self.gird = C(UIGrid,trans,"EquipShow/GetEquip/Grid",tip)
    self.items = {}

    self.btn = T(trans,"GtBtn",tip)

    -- 按钮事件
    local US = UITool.SetBtnClick
    US(trans, "GtBtn", tip, self.OnRetreat, self)
    US(trans,"closeBtn",tip,self.Close,self)
    US(trans,"Mask",tip,self.Close,self)

    -- 特效
    self.tx = T(trans,"UI_jjtp_bz",tip)

    self:SetLsner("Add")
end

function M:SetLsner(key)
    PrayMgr.eUpdataData[key](PrayMgr.eUpdataData,self.ShowData,self)
end

function M:OpenCustom()
    self:ShowData()
end

function M:ShowData()
    self.tx:SetActive(false)
    self.tx:SetActive(true)
    local curTimes,resTimes,icon,getexp = PrayMgr:GetData()
    if resTimes == 0 then
        UITool.SetGray(self.btn,true)
    else
        UITool.SetNormal(self.btn)
    end
    self.spend = getexp
    local bsae = GlobalTemp["139"].Value2[2]
    local allTime = PrayMgr:GetTimes()
    if allTime <= bsae then
        allTimes = PrayMgr:GetTimes() + 60 - 1
    else
        allTimes = bsae + 60
    end
    local iconAward = PrayMgr:GetCoin()
    local exp = PrayMgr:GetExp()
    self.offTimeLb.text = allTimes.."分钟"
    self.numLb.text = resTimes.."/"..curTimes
    self.spendLb.text = getexp.."元宝"
    self.iconLb.text = mathToStr(iconAward)
    self.expLb.text = mathToStr(exp)

    local awardList = PrayMgr:GetRewardList()
    local petList = PrayMgr:GetPetList()
    self:ClearItem()
    self:EquipDeal(awardList,false)
    self:EquipDeal(petList,true)

    self.gird:Reposition()
end

function M:EquipDeal(list,isEat)
    if list == nil or #list == 0 then return end
    for i,v in ipairs(list) do
        self:AddCell(v,self.girdTrans,isEat)
    end
end

function M:AddCell( good, grid,isEat)
    local cell = ObjPool.Get(UIItemCell)
    local key = good.id
    cell:InitLoadPool(grid.transform)
    cell:UpData(key,good.num)
    cell:Devour(isEat)
	table.insert(self.items, cell)
end

function M:OnRetreat()
    if RoleAssets.Gold < self.spend then
        StoreMgr.JumpRechange()
        return
    end
    PrayMgr:ReqReward()
end

function M:ClearItem()
    while self.items and #self.items > 0 do
        local item = self.items[#self.items]
        item:Devour(false)
        item:DestroyGo()
        ObjPool.Add(item)
        self.items[#self.items] = nil
	end
end

function M:Clear()
    self:SetLsner("Remove")
    self:ClearItem()
end

return M