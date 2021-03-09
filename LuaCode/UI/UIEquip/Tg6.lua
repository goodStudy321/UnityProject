--[[
 	authors 	:Liu
 	date    	:2019-3-1 15:35:00
 	descrition 	:铸魂
--]]

Tg6 = Super:New{Name = "Tg6"}
local My = Tg6

function My:Init(go)
    local des = self.Name
    local root = go.transform
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "tipsBg/Scroll View"

    self.go = go
    self.class = 0
    self.cfgId = 0
    if not self.starList then self.starList = {} end
    if not self.proList then self.proList = {} end
    self.itemName = CG(UILabel, root, "pros/item/lab")
    self.classLab = CG(UILabel, root, "pros/starBg/lab1")
    self.starLab = CG(UILabel, root, "pros/starBg/lab2")
    self.desLab = CG(UILabel, root, "labBg/lab")
    self.proLab1 = CG(UILabel, root, "pros/bg1/pro1/lab1")
    self.proLab2 = CG(UILabel, root, "pros/bg1/pro1/lab2")
    self.proLab3 = CG(UILabel, root, "pros/bg1/pro2")
    self.proLab4 = CG(UILabel, root, "pros/bg1/pro2/lab1")
    self.proLab5 = CG(UILabel, root, "pros/bg1/pro2/lab2")
    self.proLab6 = CG(UILabel, root, "pros/bg2/pro1")
    self.proLab7 = CG(UILabel, root, "pros/bg2/pro1/lab1")
    self.proLab8 = CG(UILabel, root, "pros/bg2/pro2")
    self.proLab9 = CG(UILabel, root, "pros/bg2/pro2/lab1")
    self.expendLab = CG(UILabel, root, "pros/spr/lab2")
    self.sView = CG(UIScrollView, root, str)
    self.proGrid = CG(UIGrid, root, str.."/Grid")
    self.gridTran = Find(root, "pros/starBg/Grid", des)
    self.parent = Find(root, "pros/item", des)
    self.tipsBg = FindC(root, "tipsBg", des)
    self.btn = FindC(root, "pros/bg2/btn", des)
    self.yes = FindC(root, "pros/bg2/yes", des)
    self.no = FindC(root, "pros/bg2/no")
    self.proItem = FindC(root, str.."/Grid/item")
    self.starItem = FindC(root, "pros/starBg/Grid/item", des)
    self.red1 = FindC(root, "btn1/red", des)
    self.btn1 = FindC(root, "btn1", des)
    self.eff = FindC(root, "UI_zh", des)
    self.eff1 = FindC(root, "UI_zh_kq", des)
    -- self.red2 = FindC(root, "pros/bg2/btn/red", des)

    SetB(root, "btn1", des, self.OnBtn1, self)
    SetB(root, "btn2", des, self.OnBtn2, self)
    SetB(root, "pros/bg2/btn", des, self.OnBtn3, self)
    SetB(root, "tipsBg/mask", des, self.OnMask, self)
    SetB(root, "getBtn", des, self.OnGetBtn, self)

    self:InitStar()
    self:CreateTimer()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpExpendLab, self)
    EquipMgr.eForgeSoul[func](EquipMgr.eForgeSoul, self.UpData, self)
    UIEquipCell.eClick[func](UIEquipCell.eClick, self.ClickCell, self)
end

--点击装备
function My:ClickCell(part)
    self:UpData(6, part)
end

--点击获取途径按钮
function My:OnGetBtn()
    UIMgr.Open(UIGetWay.Name, self.GetWatCb, self)
end

--打开获取途径面板回调
function My:GetWatCb()
	local ui = UIMgr.Get(UIGetWay.Name)
	if ui then
		local pos = Vector3.New(-10, -140, 0)
		ui:SetPos(pos)
		ui:CreateCell("镇魂塔", self.OnGetWayItem, self)
	end
end

--点击获取途径项
function My:OnGetWayItem(name)
    if name == "镇魂塔" then
        local _, isOpen, _, lv = CopyMgr:GetCurCopy(CopyType.ZHTower)
        if not isOpen then 
            UITip.Log(string.format("%s开启", UserMgr:chageLv(lv)))
            return 
        end
        UICopyTowerPanel:Show(CopyType.ZHTower)
        JumpMgr:InitJump(UIEquip.Name, 6)
	end
end

--更新数据
function My:UpData(tb, part)
    if part == nil then return end
    if tb == 21 then
        UITip.Log("激活成功")
        self:SetEff(self.eff1)
    elseif tb == 22 then
        UITip.Log("铸魂成功")
        self:SetEff(self.eff)
    end
    self.part = part
    self:UpCell(part)
    self:UpProperty(part)
    self:UpActivateInfo(part)
    for k,v in pairs(EquipMgr.hasEquipDic) do
        local cfg = EquipBaseTemp[tostring(v.type_id)]
        local part = tostring(cfg.wearParts)
    end
end

--点击铸魂
function My:OnBtn1()
    local data = (self.cfg==nil) and EquipMgr:GetDataFromPart(self.part) or self.cfg
    local isUp = EquipMgr:IsUpgrade(data.id)
    if not isUp then
        UITip.Log("阶级已满")
        return
    elseif RoleAssets.Essence < data.expend then
        UITip.Log("材料不足")
        return
    end
    local id = self:GetEquipId(self.part)
    EquipMgr:ReqUpgrade(id)
end

--点击铸魂预览
function My:OnBtn2()
    self:UpTipsBg()
    self:UpProPop(self.part)
end

--点击激活
function My:OnBtn3()
    local id = self:GetEquipId(self.part)
    EquipMgr:ReqActivte(id, self.cfgId)
end

--点击遮罩
function My:OnMask()
    self.tipsBg:SetActive(false)
end

--更新属性弹窗
function My:UpProPop(part)
    if part == nil then return end
    self:DestroyGo()
    local Add = TransTool.AddChild
    local list = self:GetCfgsFromPart(part)
    for i,v in ipairs(list) do
        local go = Instantiate(self.proItem)
        local tran = go.transform
        go:SetActive(true)
        Add(self.proGrid.transform, tran)
        table.insert(self.proList, tran)
    end
    self:UpProPopLab(part)
    self.sView:ResetPosition()
    self.proGrid:Reposition()
end

--更新属性弹窗文本
function My:UpProPopLab(part)
    local CG = ComTool.Get
    local proList = self.proList
    local strList = SignInfo.strList
    local list = self:GetCfgsFromPart(part)
    local isOpen = EquipMgr:IsCasting(part)
    for i,v in ipairs(list) do
        local class = self:GetProClass(part)
        local lab1 = CG(UILabel, proList[i], "lab1")
        local lab2 = CG(UILabel, proList[i], "lab2")
        local str1 = (class >= v.class and isOpen) and "[00FF00FF](已" or "[F21919FF](未"
        local str2 = string.format("[F4DDBDFF]%s阶铸魂属性%s激活）", strList[v.class], str1)
        local name = self:GetProStr(v.pro, 0)
        local val = self:GetProStr(v.pro, 1)
        lab1.text = str2
        lab2.text = string.format("%s+%s", name, val)
    end
end

--获取属性激活等级
function My:GetProClass(part)
    local tb = EquipMgr.hasEquipDic[part]
    if tb == nil then return 0 end
    local id = tb.forgeSoulProId
    if id == 0 then return 0 end
    local cfg, index = BinTool.Find(CastingSoulProCfg, id)
    if cfg == nil then return 0 end
    return cfg.class
end

--根据部位id获取配置列表
function My:GetCfgsFromPart(part)
    local list = {}
    for i,v in ipairs(CastingSoulProCfg) do
        local temp = math.floor((v.id % 1000)/10)
        if tonumber(part) == temp then
            table.insert(list, v)
        end
    end
    return list
end

--销毁物体
function My:DestroyGo()
    local len = #self.proList
    for i=len, 1, -1 do
        local list = self.proList
        if list[i] then
            local go = list[i].gameObject
            go:SetActive(false)
            Destroy(go)
            table.remove(list, #list)
        end
    end
end

--更新道具
function My:UpCell(part)
    local equip = EquipMgr.hasEquipDic[part]
    if equip == nil then return end
    local id = equip.type_id
    local cfg = ItemData[tostring(id)]
    if cfg == nil then return end
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.parent)
    end
    self.cell:UpData(id)
    self.itemName.text = cfg.name
end

--更新激活信息
function My:UpActivateInfo(part)
    local tb = EquipMgr.hasEquipDic[part]
    if tb == nil then return 0 end
    local cfg, index = BinTool.Find(CastingSoulProCfg, tb.forgeSoulProId)
    if cfg == nil then
        local data = EquipMgr:GetInfoFromPart(part)
        if data == nil then return end
        self:SetLab(data)
        self:UpState(data, false, part)
        self.cfgId = data.id
        return
    end
    local temp, isEnd = EquipMgr:GetNextData(index)
    self:SetLab(temp)
    self:UpState(temp, isEnd, part)
    self.cfgId = temp.id
end

--更新激活状态
function My:UpState(cfg, isEnd, part)
    self:SetState(false, isEnd, not isEnd)
    if not EquipMgr:IsCasting(part) then
        self:SetState(false, false, true)
        return
    end
    local cond1 = self.class >= cfg.classCond
    local cond2 = CopyMgr:IsFinishCopy(cfg.layerCond, false)
    if cond1 and cond2 and not isEnd then
        self:SetState(true, false, false)
    end
end

--设置激活状态
function My:SetState(state1, state2, state3)
    self.btn:SetActive(state1)
    self.yes:SetActive(state2)
    self.no:SetActive(state3)
end

--设置激活文本
function My:SetLab(data)
    local color1 = (self.class >= data.classCond) and "[00FF00FF]" or "[F21919FF]"
    local color2 = (CopyMgr:IsFinishCopy(data.layerCond, false)) and "[00FF00FF]" or "[F21919FF]"
    self.proLab6.text = data.class.."阶铸魂属性："
    local name = self:GetProStr(data.pro, 0)
    local val = self:GetProStr(data.pro, 1)
    self.proLab7.text = string.format("%s+%s", name, val)
    self.proLab8.text = string.format("%s部位铸魂至%s阶", color1, data.classCond)
    self.proLab9.text = string.format("%s通关镇魂塔%s层", color2, data.layerCond-50000)
end

--获取属性字段
function My:GetProStr(proList, type)
    local name = ""
    local val = ""
    for i,v in ipairs(proList) do
        local info = PropName[v.k]
        name = (i==#proList) and name..info.name or name..info.name..","
        local temp1 = (info.show==1) and (v.v/10000*100).."%" or v.v
        val = (i==#proList) and val..temp1 or val..temp1.."+"
    end
    local temp2 = (type==0) and name or val
    return temp2
end

--更新铸魂按钮状态
function My:UpBtnState(cfg, part)
    if not EquipMgr:IsCasting(part) then
        UITool.SetGray(self.btn1)
        return
    end
    UITool.SetNormal(self.btn1)
    self.red1:SetActive(false)
end

--更新属性
function My:UpProperty(part)
    local id = EquipMgr:GetId(part)
    local cfg, index = BinTool.Find(CastingSoulCfg, id)
    if cfg == nil then
        self.cfg = nil
        self:UpStar(1, 0)
        self:UpLvShow(1, 0)
        self:UpProShow(nil, part)
        self:UpNextLv(0, part, nil)
        self:UpExpendLab()
        self:UpBtnState(nil, part)
        self.class = 0
        return
    end
    local class, star = EquipMgr:GetClass(cfg)
    self.class = class
    self.cfg = cfg
    self:UpStar(class, star)
    self:UpLvShow(class, star)
    self:UpProShow(cfg, part)
    self:UpNextLv(index, part, cfg)
    self:UpExpendLab()
    self:UpBtnState(cfg, part)
end

--更新消耗文本
function My:UpExpendLab()
    local str = 0
    local cfg = self.cfg
    local part = self.part
    if cfg == nil then
        local data = EquipMgr:GetDataFromPart(part)
        if data == nil then return end
        str = data.expend
    else
        str = (self.nextExpend==nil) and "???" or self.nextExpend
    end
    self.expendLab.text = string.format("%s/%s", RoleAssets.Essence, str)
end

--更新铸魂预览
function My:UpTipsBg()
    self.tipsBg:SetActive(true)
end

--更新阶级显示
function My:UpLvShow(class, star)
    self.proLab1.text = string.format("%s阶%s星", class, star)
end

--更新属性显示
function My:UpProShow(cfg, part)
    if cfg == nil then
        local data = EquipMgr:GetDataFromPart(part)
        if data == nil then return end
        local name1 = self:GetProStr(data.pro, 0)
        self.proLab3.text = name1.."："
        local temp = ""
        for i,v in ipairs(data.pro) do
            temp = temp.."+0"
        end
        self.proLab4.text = temp
        return
    end
    local name2 = self:GetProStr(cfg.pro, 0)
    local val2 = self:GetProStr(cfg.pro, 1)
    self.proLab3.text = name2.."："
    self.proLab4.text = "+"..val2
end

--更新下一个阶级显示
function My:UpNextLv(index, part, cfg)
    if index == 0 or cfg == nil then
        self.proLab2.text = string.format("%s阶%s星", 1, 1)
        local data = EquipMgr:GetDataFromPart(part)
        if data == nil then return end
        local val = self:GetProStr(data.pro, 1)
        self.proLab5.text = "+"..val
        return
    end
    local temp1 = EquipMgr:GetNextCfg(index)
    local temp2, idx = BinTool.Find(CastingSoulCfg, temp1.id)
    local class, star = EquipMgr:GetClass(temp2)
    -- local val = self:GetNextProStr(cfg.pro, cfg.id)
    local val = self:GetProStr(temp2.pro, 1)
    self.proLab2.text = string.format("%s阶%s星", class, star)
    self.proLab5.text = "+"..val
    self.nextExpend = temp2.expend
end

--更新星级
function My:UpStar(class, star)
    local list = SignInfo.strList
    local str = (star==0) and "零" or list[star]
    self.classLab.text = class.."阶"
    self.starLab.text = star.."星"
    self.desLab.text = string.format("%s阶%s星", list[class], str)
    for i,v in ipairs(self.starList) do
        v:SetActive(star >= i)
    end
end

--初始化星级
function My:InitStar()
    local Add = TransTool.AddChild
    local FindC = TransTool.FindChild
    for i=1, 10 do
        local go = Instantiate(self.starItem)
        local tran = go.transform
        local star = FindC(tran, "star", des)
        Add(self.gridTran, tran)
        table.insert(self.starList, star)
    end
    self.starItem:SetActive(false)
end

--获取装备ID
function My:GetEquipId(part)
    local tb = EquipMgr.hasEquipDic[part]
    if tb == nil then return 0 end
    return tb.type_id
end

--切换分页
function My:SwatchTg()
	UIEquip.eSwatchTg(5)
end

--显示
function My:Open()
    -- self:SetLnsr("Add")
    self.go:SetActive(true)
end

--隐藏
function My:Close()
    -- self:SetLnsr("Remove")
    self.go:SetActive(false)
end

--设置特效
function My:SetEff(eff)
    eff:SetActive(false)
    eff:SetActive(true)
    self:UpTimer(1)
end

--更新计时器
function My:UpTimer(rTime)
	if self.timer == nil then return end
	local timer = self.timer
	timer.seconds = rTime
	timer:Start()
end

--创建计时器
function My:CreateTimer()
	if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()

end

--结束倒计时
function My:EndCountDown()
    self.eff:SetActive(false)
    self.eff1:SetActive(false)
end

--清空计时器
function My:ClearTimer()
    if self.timer then
        self.timer:Stop()
		self.timer:AutoToPool()
        self.timer = nil
    end
end

--清理缓存
function My:Clear()
    self.class = nil
    self.part = nil
    self.cfg = nil
    self.cfgId = nil
    self.nextExpend = nil
    self:ClearTimer()
end
    
--释放资源
function My:Dispose()
    if self.starList then ListTool.Clear(self.starList) end
    if self.proList then ListTool.Clear(self.proList) end
    self:Close()
    self:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil
    end
    self:SetLnsr("Remove")
end

return My