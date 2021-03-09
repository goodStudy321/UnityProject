--[[
    道具出售提示
]]
-- PropSaleTip = UIBase:New{Name = "PropSaleTip"}
-- local M = PropSaleTip

-- function M:InitCustom()
--     local root = self.root
--     local C = ComTool.Get
--     local T = TransTool.FindChild
--     local US = UITool.SetLsnrClick

--     US(root, "useBtn", "", self.UseBySelf, self)
--     US(root, "saleBtn", "", self.Sale, self)
--     US(root, "CloseBtn", "", self.Close, self)

--     self.name = C(UILabel,root,"name",tip,false)
--     self.minPrice = C(UILabel,root,"minPrice",tip,false)
--     self.maxPrice = C(UILabel,root,"maxPrice",tip,false)

--     self.cell = T(root,"cell")
--     self.Cell=ObjPool.Get(Cell)
--     self.Cell:InitLoadPool(self.cell.transform)
    
--     Cell.eMarketShow["Add"](Cell.eMarketShow, self.Close, self)
-- end

-- function M:UpData(item, tb)
--     self.item = item
--     self.tb = tb
--     self.itemUid = tb.id
--     self.tbNum = tb.num
--     local data = ItemData[tostring(item.id)]
--     self.Cell:UpData(item)
--     self.Cell:ShowLimit(tb.market_end_time)
--     self.Cell:UpBind(false)
--     local qua = UIMisc.LabColor(item.quality)
--     self.name.text = qua..item.name
--     self.minPrice.text = data.priceInt[1]
--     self.maxPrice.text = data.priceInt[2]
-- end

-- --自己使用
-- function M:UseBySelf()
--     -- if self.item.uFx == 1 then
--     --     local typeId = self.tb.type_id
--     --     local equip = EquipBaseTemp[tostring(typeId)]
--     --     if(self.item.canUse==1)then
--     --         local part = equip.wearParts
--     --         local tb = EquipMgr.hasEquipDic[tostring(part)]
--     --         if(tb~=nil and tb.suitLv~=nil and tb.suitLv~=0)then
--     --             local title="您换下的为[67cc67]套装部件[-]，且无法转移到新的装备上，是否更换该装备[67cc67]（返还全部套装石头）[-]?"			
--     --             MsgBox.ShowYesNo(title, self.EquipCb,self)
--     --         elseif EquipMgr:IsTips(tostring(part), self.item.id) then
--     --             local title="替换会使铸魂效果暂时失效，是否确认替换？"			
--     --             MsgBox.ShowYesNo(title, self.EquipCb,self)
--     --         else
--     --             self:EquipCb()
--     --         end			
--     --     else
--     --         UITip.Log("不能穿戴")
--     --     end
--     -- else
--     --     QuickUseMgr.PropUse(self.item,self.itemUid,self.tbNum,1)
--     -- end
--     -- UIMgr.Close(self.Name)
-- end

-- -- function M:EquipCb()
-- -- 	local useLv = self.item.useLevel or 1
-- -- 	if(User.MapData.Level<useLv)then
-- -- 		UITip.Log("等级不足，无法穿戴")
-- -- 		return
-- -- 	end
-- -- 	PropMgr.ReqUse(self.tb.id,1)
-- -- end

-- -- 上架
-- function M:Sale()
--     UIMgr.Open(PropSale.Name,self.PropCb,self)
--     UIMgr.Close(self.Name)
-- end

-- function M:PropCb(name)
--     local ui = UIMgr.Get(name)
--     if(ui)then
--         ui:ShowWidge(true)
--         ui:UpData(self.item,self.tb)
-- 	end
-- end

-- -- 清理数据
-- function M:DisposeCustom()
--     Cell.eMarketShow["Remove"](Cell.eMarketShow, self.Close, self)
--     self.Cell:DestroyGo()
-- 	ObjPool.Add(self.Cell)
-- end

-- return M