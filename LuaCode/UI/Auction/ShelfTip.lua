--[[
    道具出售提示
]]
ShelfTip = UIBase:New{Name = "ShelfTip"}
local M = ShelfTip

M.mSelectDic = {}

function M:InitCustom()
    local root = self.root
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick

    US(root, "useBtn", "", self.UseBySelf, self)
    US(root, "saleBtn", "", self.Sale, self)
    US(root, "CloseBtn", "", self.Close, self)
    US(root, "BtnAdd", "", self.OnAdd, self)
    US(root, "BtnReduce", "", self.OnReduce, self)
    US(root, "Count", "", self.OnInput, self)
    

    self.name = C(UILabel,root,"name",tip,false)
    self.twoPrice = C(UILabel,root,"twoPrice",tip,false)
    self.onePrice = C(UILabel,root,"onePrice",tip,false)
    self.mCount = C(UILabel, root, "Count")

    self.cell = T(root,"cell")
    self.Cell=ObjPool.Get(Cell)
    self.Cell:InitLoadPool(self.cell.transform)
    
    --Cell.eMarketShow["Add"](Cell.eMarketShow, self.Close, self)
    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    PricePanel.eConfirm[key](PricePanel.eConfirm, self.OnConfirm, self)
end

function M:OnInput()
    UIMgr.Open(PricePanel.Name)
end

function M:OnConfirm(num)
    num = num > 0 and num or 1
    self.curCount = num > self.tb.num and self.tb.num or num
    self:UpdatePrice(self.curCount)
end

function M:OnAdd()
    self.curCount = self.curCount + 1
    if self.curCount > self.tb.num then
        self.curCount = self.tb.num
    end
    self:UpdatePrice(self.curCount)
end

function M:OnReduce()
    self.curCount = self.curCount - 1
    if self.curCount < 1 then
        self.curCount = 1
    end
    self:UpdatePrice(self.curCount)
end

function M:UpdatePrice(num)
    local data = self.data
    self.twoPrice.text = data.startPrice * num
    self.onePrice.text = data.fixedPrice * num
    self.mCount.text = num
    self.mSelectDic[tostring(self.tb.id)] = num
end

function M:UpData(tb)
    --self.item = item
    local id = tb.type_id
    self.tb = tb
    local num = tb.num
    local data = ItemData[tostring(id)]
    self.data = data
    self.Cell:UpData(id)
    self.Cell:ShowLimit(tb.market_end_time)
    self.Cell:UpBind(false)
    local qua = UIMisc.LabColor(data.quality)
    self.name.text = qua..data.name
    self.curCount = num
    self:UpdatePrice(num)
end

--自己使用
function M:UseBySelf()
    -- if self.item.uFx == 1 then
    --     local typeId = self.tb.type_id
    --     local equip = EquipBaseTemp[tostring(typeId)]
    --     EquipMgr.SetCurEquipTipData(self.item,equip,self.tb)
    --     EquipMgr.OnEquip()
    -- else
    --     QuickUseMgr.PropUse(self.item,self.itemUid,self.tbNum,1)
    -- end
    AuctionMgr:ReqUseSelf(self.mSelectDic)
    local item = UIMisc.FindCreate(self.tb.type_id)
    local uFx = item.uFx
    if uFx==1 then
		QuickUseMgr.PropUse(item,self.id,1)
	elseif uFx==82 then
		SkillMgr:quickUpLv(item,self.tb.id)
	elseif uFx==85 then 
		SkillMgr:quickUpLv(item,self.tb.id)
	else
		-- local num = PropMgr.TypeIdByNum(item.id)
        -- QuickUseMgr.PropUse(item,self.tb.id,num)
        QuickUseMgr.PropNotLimitUse(item,self.tb.id,self.curCount)
	end
    UIMgr.Close(self.Name)
end

-- 上架
function M:Sale()
    local tb = self.tb;
    local now = TimeTool.GetServerTimeNow()*0.001
    if tb.market_end_time - now > 0 then
        local timeStr = self:ApproximateTime(tb.market_end_time - now);
        local str = string.format("从拍卖行购买的道具不能立即上架，请%s后再试", timeStr);
        UITip.Log(str);
    else
        AuctionMgr:ReqOnShelf(self.mSelectDic)
    end
    UIMgr.Close(self.Name)
end

--// 大致时间
function M:ApproximateTime(sec)
    local str = "";
    if sec/3600 > 1 then
        str = StrTool.Concat(tostring(math.floor(sec/3600)), "小时");
    else
        if sec/60 > 1 then
            str = StrTool.Concat(tostring(math.floor(sec/60)), "分钟");
        else
            str = StrTool.Concat(tostring(sec), "秒");
        end
    end
    return str;
end

-- 清理数据
function M:DisposeCustom()
    self:SetLsnr("Remove")
    --Cell.eMarketShow["Remove"](Cell.eMarketShow, self.Close, self)
    TableTool.ClearDic(self.mSelectDic)
    self.Cell:DestroyGo()
	ObjPool.Add(self.Cell)
end

return M