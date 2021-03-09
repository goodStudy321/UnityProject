--[[
 	authors 	:Liu
 	date    	:2018-11-5 16:30:00
 	descrition 	:仙魂等级弹窗
--]]

UIImmSoulLvPop = Super:New{Name = "UIImmSoulLvPop"}

local My = UIImmSoulLvPop

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick

    -- SetB(root, "bg/box", des, self.OnPop, self)
    SetB(root, "close", des, self.OnClose, self)
    SetB(root, "UpBtn", des, self.OnLvUp, self)
    self.tex = CG(UITexture, root, "desBg/cell/icon")
    self.cellBg = CG(UISprite, root, "desBg/cell/cellBg")
    self.nameLab = CG(UILabel, root, "desBg/lab1")
    self.pro1Lab = CG(UILabel, root, "desBg/lab2")
    -- self.pro1Spr = FindC(root, "desBg/lab2/spr", des)
    self.proUp1Lab = CG(UILabel, root, "desBg/lab2/lab")
    self.pro2Lab = CG(UILabel, root, "desBg/lab3")
    -- self.pro2Spr = FindC(root, "desBg/lab3/spr", des)
    self.proUp2Lab = CG(UILabel, root, "desBg/lab3/lab")
    self.needLab = CG(UILabel, root, "desBg/lab4/lab")
    self.yPos = self.pro1Lab.transform.localPosition.y
    self.go = root.gameObject
end

--更新数据
function My:UpData(cfg, pos)
    self.cfg = cfg
    self.pos = pos
    self:UpShow(true)
    self:SetCellBg(cfg)
    self:SetLab(cfg)
end

--设置格子背景
function My:SetCellBg(cfg)
    local bg = self.cellBg
    bg.gameObject:SetActive(true)
    local qua = math.floor(cfg.id % 10)
    local str = ImmortalSoulInfo:GetCellBg(qua)
    bg.spriteName = str
end

--设置文本
function My:SetLab(cfg)
    self:SetTex(cfg)
    self:SetNameLab(cfg)
    self:UpProLab(cfg)
    self:UpNeedLab(cfg)
end

--更新文本
function My:UpLab()
    local upCfg = self:GetUpCfg()
    self.cfg = upCfg
    self:SetNameLab(upCfg)
    self:UpProLab(upCfg)
    self:UpNeedLab(upCfg)
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

--设置名字文本
function My:SetNameLab(cfg)
    local num = math.floor((cfg.id - 90000000) / 100000)
    local str = string.format("%sLv.%s", cfg.name, num)
    self.nameLab.text = str
end

--更新属性文本
function My:UpProLab(cfg)
    local upCfg = self:GetUpCfg()
    self:SetProLab(cfg.pro1, self.pro1Lab, self.proUp1Lab, cfg.proVal1, 1, upCfg)
    self:SetProLab(cfg.pro2, self.pro2Lab, self.proUp2Lab, cfg.proVal2, 2, upCfg)
end

--设置属性文本
function My:SetProLab(num, lab, lab1, val, index, upCfg)
    lab.gameObject:SetActive(false)
    if num == 0 then
        self:UpLabPos(-37)
    else
        local cfg = PropName[num]
        if cfg == nil then return end
        local str = ""
        local upStr = ""
        local value = (cfg.show==1) and string.format("%.2f", val/10000*100).."%" or val
        if upCfg == nil then
            str = string.format("%s %s", cfg.name, value)
            upStr = "已满级"
        else
            
            local value1 = (cfg.show==1) and string.format("%.2f", upCfg.proVal1/10000*100).."%" or upCfg.proVal1
            local value2 = (cfg.show==1) and string.format("%.2f", upCfg.proVal2/10000*100).."%" or upCfg.proVal2
            local upVal = (index==1) and value1 or value2
            str = string.format("%s %s", cfg.name, value)
            upStr = string.format("+%s", upVal)
        end
        lab.text = str
        lab1.text = upStr
        lab.gameObject:SetActive(true)
    end
    if index == 2 and num ~= 0 then
		self:UpLabPos(self.yPos)
	end
end

--更新文本位置
function My:UpLabPos(y)
	local tran = self.pro1Lab.transform
	tran.localPosition = Vector3.New(tran.localPosition.x, y, 0)
end

--更新升级所需文本
function My:UpNeedLab(cfg)
    local info = ImmortalSoulInfo
    local color = (info.debris < cfg.needDebris) and "[F21919FF]" or "[F4DDBDFF]"
    local str = string.format("%s%s[F39800FF]/%s", color, info.debris, cfg.needDebris)
    self.needLab.text = str
end

--获取下一级的属性值
function My:GetUpCfg()
    local num = math.floor(self.cfg.id + 100000)
    local cfg, temp = BinTool.Find(ImmSoulLvCfg, num)
    return cfg
end

--点击升级
function My:OnLvUp()
    local upCfg = self:GetUpCfg()
    if upCfg == nil then
        UITip.Log("仙魂等级已满")
        return
    else
        if not self:IsLvUp(self.cfg) then return end
        ImmortalSoulMgr:ReqLvUp(self.pos)
    end
end

--判断是否能升级
function My:IsLvUp(cfg)
    local info = ImmortalSoulInfo
    if info.debris < cfg.needDebris then
        UITip.Log("仙尘不足无法升级")
        return false
    else
        return true
    end
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--点击升级弹窗
-- function My:OnPop()
--     self:UpShow(false)
-- end

--点击关闭
function My:OnClose()
    self.cellBg.gameObject:SetActive(false)
    self:UpShow(false)
    AssetMgr:Unload(self.texName, false)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName, false)
end

--释放资源
function My:Dispose()
    self:Clear()
end

return My