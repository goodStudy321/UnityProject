--[[
 	authors 	:Liu
 	date    	:2018-11-5 14:30:00
 	descrition 	:仙魂详情弹窗
--]]

ImmortalSoulTip = UIBase:New{Name = "ImmortalSoulTip"}

local My = ImmortalSoulTip

function My:InitCustom()
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local SetS = UITool.SetLsnrSelf
    local root = self.root

    self.tex = CG(UITexture, root, "tipBg/top/icon")
    self.bg = CG(UISprite, root, "tipBg/top/bg")
    self.cellBg = CG(UISprite, root, "tipBg/top/cell")
    self.nameLab = CG(UILabel, root, "tipBg/top/lab1")
    self.posLab = CG(UILabel, root, "tipBg/top/lab2")
    self.lvLab = CG(UILabel, root, "tipBg/top/lab3")
    self.pro1Lab = CG(UILabel, root, "tipBg/pro1/lab1")
    self.pro2Lab = CG(UILabel, root, "tipBg/pro1/lab2")
    self.title1Lab = CG(UILabel, root, "tipBg/pro1/title")
    self.decompLab = CG(UILabel, root, "tipBg/pro2/lab")
    self.getLab = CG(UILabel, root, "tipBg/pro3/lab")
    self.equipLab = CG(UILabel, root, "tipBg/btns/btn3/lab")
    self.lvUpLab = CG(UILabel, root, "tipBg/btns/btn2/lab")
    self.btn1Tran = Find(root, "tipBg/btns/btn1", des)
    self.btn2Tran = Find(root, "tipBg/btns/btn2", des)
    self.btn3Tran = Find(root, "tipBg/btns/btn3", des)
    self.btns = Find(root, "tipBg/btns", des)
    SetB(root, "box", des, self.OnTip, self)
    SetS(self.btn1Tran, self.OnComp, self, des)
    SetS(self.btn2Tran, self.OnLvUp, self, des)
    SetS(self.btn3Tran, self.OnEquip, self, des)
    self.tipBg = Find(root, "tipBg", des)

    UITool.SetLsnrClick(self.root,"transBg",self.Name,self.Close,self)
end

--更新数据
function My:UpData(cfg, index, cellId)
    self.cfg = cfg
    self.index = index
    self.cellId = cellId
    self:SetState(index)
    self:SetLab(cfg)
end

--点击合成
function My:OnComp(go)
   local info = ImmortalSoulInfo
   local index, tabId = info:GetJumpInfo(self.cfg.id)
   if index ~= nil then
    info:SetTogIndex(index)
    info:SetTabIndex(tabId)
   end
   UIImmortalSoul:UpShow(2)
end

--点击升级/分解
function My:OnLvUp(go)
    local it = UIImmortalSoul
    if self.index == 1 then
        it:InitModule3()
        it.mod3:SelectDecomp(self.cellId)
    else
        it:ShowLvUpPop(self.cfg, self.cellId)
    end
end

--点击装备/卸下
function My:OnEquip(go)
    local info = ImmortalSoulMgr
    if self.index == 1 then
        local pos = self:IsEquip()
        if not pos then return end
        info:ReqEquip(self.cellId, pos)
    else
        local bag = UIImmortalSoul.mod1.bag
        bag:RefreshBag()
        local isCell = bag:IsCell()
        if isCell == nil then
            UITip.Log("请检查背包是否有空位")
            return
        end
        info:ReqUnload(self.cellId)
    end
end

--判断是否能装备
function My:IsEquip()
    local cfg = self.cfg
    local id = ImmortalSoulInfo:GetBaseID(cfg.id)
    local key = tostring(id)
    local baseCfg = ImmSoulCfg[key]
    if baseCfg == nil then return false end
    local type = baseCfg.wearType
    local typeList = baseCfg.proType
    for i,v in ipairs(typeList) do
        local isSame = ImmortalSoulInfo:IsSameType(v)
        if isSame then
            UITip.Log("已镶嵌有相同类型的仙魂")
            return false
        end
    end
    if type == 0 then
        UITip.Log("该类型的仙魂不能装备")
        return false
    elseif type == 1 then
        local pos = UIImmortalSoul:GetPos()
        if pos == nil then
            UITip.Log("普通类型已满，没有可镶嵌的位置")
            return false
        else
            return pos
        end
    elseif type == 2 then
        local pos = UIImmortalSoul:GetCorePos()
        if pos == nil then
            UITip.Log("核心类型已满，没有可镶嵌的位置")
            return false
        elseif pos == 0 then
            UITip.Log("核心位置尚未开启")
            return false
        else
            return pos
        end
    end
end

--设置装备文本
function My:SetState(index)
    if index == 1 then
        self:SetBtn(0, -88, "装备", "分解")
    elseif index == 2 then
        self:SetBtn(-445, 375, "卸下", "升级")
    elseif index == 3 then
        self:SetBgPos(230)
        self:ShowBtn(false, false, false)
    end
end

--设置按钮
function My:SetBtn(pos1, pos2, str1, str2)
    self:SetBtnState(pos1)
    self:SetBgPos(pos2)
    self.equipLab.text = str1
    self.lvUpLab.text = str2
    local isShow = ImmortalSoulInfo:IsShowJump(self.cfg.id)
    if not isShow then
        self:ShowBtn(false, true, true)
    end
end

--显示按钮
function My:ShowBtn(state1, state2, state3)
    self.btn1Tran.gameObject:SetActive(state1)
    self.btn2Tran.gameObject:SetActive(state2)
    self.btn3Tran.gameObject:SetActive(state3)
end

--设置按钮状态
function My:SetBtnState(btnsPos)
    self:ShowBtn(true, true, true)
    self.btns.localPosition = Vector3.New(btnsPos, 0, 0)
end

--设置文本
function My:SetLab(cfg)
    self:SetTex(cfg)
    self:SetBg(cfg)
    self:SetNameLab(cfg)
    self:SetPosStr(cfg)
    self:SetLvLab(cfg)
    self:UpProLab(cfg)
    self.decompLab.text = cfg.getDebris
    self.getLab.text = "【幽魂林】"
end

--设置名字文本
function My:SetNameLab(cfg)
    local qua = math.floor(cfg.id % 10)
    local color = UIMisc.LabColor(qua)
    local str = string.format("%s%s", color, cfg.name)
    self.nameLab.text = str
end

--更新属性文本
function My:UpProLab(cfg)
    local num = math.floor(cfg.id + 100000)
    local upCfg, temp = BinTool.Find(ImmSoulLvCfg, num)
    self.title1Lab.text = "基础属性"
    self:SetProLab(cfg.pro1, self.pro1Lab, cfg.proVal1, 1, upCfg)
    self:SetProLab(cfg.pro2, self.pro2Lab, cfg.proVal2, 2, upCfg)
    self:SetDebrisLab(cfg.id, cfg.proVal1)
end

--设置属性文本
function My:SetProLab(num, lab, val, index, upCfg)
    if num == 0 then
        lab.gameObject:SetActive(false)
    else
        lab.gameObject:SetActive(true)
        local cfg = PropName[num]
        if cfg == nil then return end
        local str = ""
        local value = (cfg.show==1) and string.format("%.2f", val/10000*100).."%" or val
        if upCfg == nil then
            str = string.format("[F4DDBDFF]%s  %s", cfg.name, value)
        else
            local value1 = (cfg.show==1) and string.format("%.2f", upCfg.proVal1/10000*100).."%" or upCfg.proVal1
            local value2 = (cfg.show==1) and string.format("%.2f", upCfg.proVal2/10000*100).."%" or upCfg.proVal2
            local upVal = (index==1) and value1 or value2
            str = string.format("[F4DDBDFF]%s  %s[00FF00FF]（强化  +%s）", cfg.name, value, upVal)
        end
        lab.text = str
    end
end

--设置碎片显示文本
function My:SetDebrisLab(id, proVal)
    if proVal == 0 then
        local cfg = ItemData[tostring(id)]
        if cfg == nil then return end
        self.title1Lab.text = "道具描述"
        self.pro1Lab.gameObject:SetActive(true)
        self.pro1Lab.text = string.format("[F4DDBDFF]%s", cfg.des)
    end
end

--设置贴图
function My:SetTex(cfg)
    local id = ImmortalSoulInfo:GetBaseID(cfg.id)
    local key = tostring(id)
    local baseCfg = ImmSoulCfg[key]
    if baseCfg == nil then return end
    self.texName = baseCfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--回调方法
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--根据品质设置背景
function My:SetBg(cfg)
    local qua = math.floor(cfg.id % 10)
    local str = ImmortalSoulInfo:GetCellBg(qua)
    self.cellBg.spriteName = str
    local bg = self.bg
    if qua == 1 then
        bg.spriteName = "cell_a01"
    elseif qua == 2 then
        bg.spriteName = "cell_a02"
    elseif qua == 3 then
        bg.spriteName = "cell_a03"
    elseif qua == 4 then
        bg.spriteName = "cell_a04"
    elseif qua == 5 then
        bg.spriteName = "cell_a05"
    end
end

--设置位置文本
function My:SetPosStr(cfg)
    local key = tostring(cfg.id)
    local baseCfg = ImmSoulCfg[key]
    if baseCfg == nil then return end
    local type = baseCfg.wearType
    local str = ""
    if type == 0 then
        str = "无法镶嵌"
    elseif type == 1 then
        str = "普通"
    elseif type == 2 then
        str = "核心"
    end
    local strs = string.format("[F4DDBDFF]装备位置： [F39800FF]%s", str)
    self.posLab.text = strs
end

--设置等级文本
function My:SetLvLab(cfg)
    local str = string.format("[F4DDBDFF]等级： [00FF00FF]%s", cfg.lv)
    self.lvLab.text = str
end

--点击详情
function My:OnTip()
    self:Close()
    AssetMgr:Unload(self.texName, false)
end

--设置背景位置
function My:SetBgPos(num)
    local bg = self.tipBg
    bg.localPosition = Vector3.New(num, bg.localPosition.y, 0)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName, false)
end

--释放资源
function My:DisposeCustom()
    self:Clear()
end

return My