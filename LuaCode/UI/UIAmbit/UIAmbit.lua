-- UIAmbit = UIBase:New{Name="UIAmbit"}

-- local M = UIAmbit

-- function M:InitCustom( ... )
--     local name = self.Name
--     local S = UITool.SetLsnrClick
--     local G = ComTool.Get
--     local F = TransTool.Find
--     local FC = TransTool.FindChild

--     local root = self. root

--     S(root, "btnClose", name, self.Close, self)
--     S(root, "btnAdv", name, self.ReqAdv, self)

--     local names = {"cur", "next"}

--     for i=1,2 do
--         local parent = F(root, names[i])
--         self["name"..i] = G(UILabel, parent, "name")
--         self["Lab_1_"..i] = G(UILabel, parent, "Lab_1")
--         self["Lab_2_"..i] = G(UILabel, parent, "Lab_2")
--         self["Lab_3_"..i] = G(UILabel, parent, "Lab_3")
--     end

--     local cond =  F(root,"condition")
--     self.power = G(UILabel, cond, "power")
--     self.grid = G(UIGrid, cond, "grid")
--     self.cell = FC(self.grid.transform, "cell")
--     self.cell:SetActive(false)
--     self.BtnGetWay = FC(cond,"BtnGetWay")
--     S(cond, "BtnGetWay", name, self.OnGetWay, self)

--     self.cellList = {}
--     self:UpData()
--     self:SetLsnr("Add")
-- end

-- function M:SetLsnr(key)
--     AmbitMgr.eUpData[key](AmbitMgr.eUpData, self.UpData, self)
-- end

-- function M:UpData(confine)
--     confine = confine or User.MapData.Confine
--     self:SetData(confine)
-- end

-- function M:SetData(index)
--     local cur = AmbitCfg[index]
--     local next = AmbitCfg[index+1]
--     local c = UIMisc.LabColor
--     local function set(data, name, Lab_1, Lab_2, Lab_3, flag)
--         local color = flag and "[f4ddbd]" or "[00FF00FF]"
--         if data  then
--             local dic = data.attrDic
--             -- name.text = string.format("%s%s[-]", c(data.quality)  ,data.name)
--             name.text = data.name
--             Lab_1.text =  string.format("[99886b]战力[-]        %s+%d[-]", color,dic[1].v) 
--             Lab_2.text =  string.format("[99886b]攻击[-]        %s+%d[-]", color,dic[2].v) 
--             Lab_3.text =  string.format("[99886b]生命[-]        %s+%d[-]", color,dic[3].v) 
--         else
--             name.text = "无"
--             Lab_1.text =  string.format("[99886b]战力[-]        %s+%d[-]", color,0) 
--             Lab_2.text =  string.format("[99886b]攻击[-]        %s+%d[-]", color,0) 
--             Lab_3.text =  string.format("[99886b]生命[-]        %s+%d[-]", color,0) 
--         end
--     end

--     set(cur, self.name1, self.Lab_1_1, self.Lab_2_1, self.Lab_3_1, true)
--     set(next, self.name2, self.Lab_1_2, self.Lab_2_2, self.Lab_3_2)

--     self:UpCellList(index)
-- end

-- function M:UpCellList(index)
--     local next = AmbitCfg[index+1]
--     if not next then
--         self.grid.gameObject:SetActive(false)
--         self.power.text = "[bfa47a]已达到最高境界[-]"
--         return
--     end 
--     local CS = math.NumToStr
--     local color = User.MapData.AllFightValue >= next.power and "[00ff00]" or "[f04d4d]"
--     self.power.text = string.format("[bfa47a]所需总战斗力：%s%s[-]/%s[-]",  color, CS(User.MapData.AllFightValue), CS(next.power))
--     local items = next.itemDic
--     local len = #items
--     local flag = len > 0
--     local grid = self.grid
--     grid.gameObject:SetActive(flag)
--     self.BtnGetWay:SetActive(flag)
--     if not flag then return end
--     local cellList = self.cellList
--     local count = #cellList

--     local max = count >= len and count or len
--     local min = count + len - max

--     for i=1, max do
--         if i <= min then
--             cellList[i]:SetActive(true)
--             cellList[i]:UpData(items[i].k, ItemTool.GetConsumeOwn(items[i].k, items[i].v))
--             cellList[i]:SetGray(PropMgr.TypeIdByNum(items[i].k)<items[i].v, true)
--         elseif i <= count then
--             cellList[i]:SetActive(false)
--         else
--             local go = Instantiate(self.cell)
--             go:SetActive(true)
--             go.name = i
--             local trans = go.transform
--             TransTool.AddChild(grid.transform, trans)
--             local cell = ObjPool.Get(UIItemCell)
--             cell:InitLoadPool(trans, 1, self, nil, function() cell:SetGray(PropMgr.TypeIdByNum(items[i].k)<items[i].v, true) end)
--             cell:UpData(items[i].k, ItemTool.GetConsumeOwn(items[i].k, items[i].v))
--             table.insert(cellList, cell)
--         end
--     end
--     grid:Reposition() 
-- end

-- function M:ReqAdv()
--     AmbitMgr:ReqAdv()
-- end

-- function M:OnGetWay()
--     UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
-- end

-- function M:OpenGetWayCb(name)
--     local ui = UIMgr.Get(name)
--     ui:SetPos(Vector3(460, -124))
--     ui:CreateCell("挂机", self.OnClickGetWayItem, self)
-- end

-- function M:OnClickGetWayItem(name)
--     UIMgr.Open(UIMapWnd.Name)
-- end

-- function M:DisposeCustom()
--     self:SetLsnr("Remove")
-- end

-- function M:Clear()
--     local list = self.cellList
--     local len = #list
--     for i=1,len do
--         list[i]:SetGray(false)
--     end
--     TableTool.ClearListToPool(self.cellList)
--     self.cellList = nil
-- end


-- return M