--[[
 	authors 	:Liu
 	date    	:2018-6-27 11:32:00
 	descrition 	:装备寻宝
--]]

UIEquipTreas = Super:New{Name="UIEquipTreas"}

local My = UIEquipTreas

local strs = "UI/UITreasure/"
require(strs.."UIEquipRoulette")
require(strs.."UIEquipTreasLog")
require(strs.."UIEquipTreasShop")
require(strs.."UIEquipTreasBag")
require(strs.."UIEquipRouletteIt")

local Animation = UnityEngine.Animation
local Renderer = UnityEngine.Renderer

function My:Init(root, index)
    local CG, Find = ComTool.Get, TransTool.Find
    local des, SetB = self.Name, UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "LuckValBg/sliderBg/"

    self.keys = 0
    self.index = index
    self.root = root
    self.rouleTran = Find(root, "rouletteBg", des)
    self.logTran = Find(root, "treasureLog", des)
    self.keyTex = CG(UITexture, root, "ScoreBg/key")
    self.scoreLab = CG(UILabel, root, "ScoreBg/hintSpr/score")
    self.keyLab = CG(UILabel, root, "ScoreBg/key/lab")
    self.goldLab = CG(UILabel, root, "ScoreBg/gold/lab")
    self.slider = CG(UISlider, root, str.."slider")
    self.sliderLab = CG(UILabel, root, str.."lab")
    -- self.icon = CG(UISprite, root, "LuckValBg/spr3/icon")
    self.shopTran = Find(root, "shopPanel", des)
    self.treasBagTran = Find(root, "StoreHouse", des)
    self.redDot = FindC(root, "depotBtn/redDot", des)
    self.model = FindC(root, "Model", des)

    self.len = 0
    self.angle = 0
    self.modelList = {}
    self.modelNameList = {}
    self.parentList = {}
    self.iconList = {}
    self.texNameList = {}
    self.texScaleList = {}
    self.cfgList = {}
    self.itList = {}
    self.anim = CG(Animation, root, "Model/XBDZ_10_anim")
    self.buyEff1 = FindC(root, "Model/XBDZ_10_anim/Point003/UI_choujiang_open", des)
    self.buyEff2 = FindC(root, "Model/fx_baohui", des)
    self.buyEff3 = FindC(root, "Model/FX_open", des)
    self.idleEff1 = FindC(root, "Model/XBDZ_10_anim/Point003/UI_choujiang_idle01", des)
    self.idleEff2 = FindC(root, "Model/FX_iidle01", des)
    self.animTime = self.anim:GetClip("XBDZ_10_idle02").length
    self.isOpen = false
    self.timer = 0
    self.ShakeTime = 1.5
    self.texIndex = 0
    self:InitTexList(root, Find, des)
    self:InitItems(root, Find, CG, des)
    self:InitIcons()
    self:InitParent()
    self:InitModelPaths()
    self:InitModel()

    SetB(root, "depotBtn", des, self.OnDepotClick, self)
    SetB(root, "shopBtn", des, self.OnShopClick, self)
    SetB(root, "ScoreBg/hintSpr", des, self.OnHelp, self)
    self:InitModule(self.rouleTran, self.logTran)
    self:InitGoldLab()
    self:InitLogs()
    self:UpRedDot()
    self:UpLuckVal()
    -- self:InitIcon()
    self:InitKeyTex()
    self:SetLnsr("Add")
end

--初始化模型
function My:InitModel()
    for i,v in ipairs(self.modelNameList) do
        UITreasure.AssetMgr.LoadPrefab(v, GbjHandler(self.LoadModCb, self))
    end
end

--加载模型
function My:LoadModCb(go)
    self.len = self.len + 1
    if self.parentList[self.len] == nil then return end
    local tran = go.transform
    tran.parent = self.parentList[self.len]
    tran.localPosition = Vector3.zero
    tran.localRotation = Quaternion.New(0,0,0,0)
    tran.localScale = Vector3.one
    LayerTool.Set(tran, 19)
    table.insert(self.modelList, go)
end

--更新模型旋转
function My:UpModelRotation()
    self.angle = self.angle + 1
    if self.angle >= 360 then self.angle = 0 end
    for i,v in ipairs(self.parentList) do
        if i < 3 then
            local x = v.localRotation.x
            local y = (i==1) and 60 or 30
            local z = v.localRotation.z
            v.localRotation = Quaternion.Euler(x, y, z + self.angle, 0)
        end
    end
end

--更新模型旋转（化神寻宝）
function My:UpTopModelRotation()
    self.angle = self.angle + 1
    if self.angle >= 360 then self.angle = 0 end
    for i,v in ipairs(self.modelList) do
        local tran = v.transform
        if i < 3 then
            local x = tran.localRotation.x
            local y = tran.localRotation.y
            local z = tran.localRotation.z
            tran.localRotation = Quaternion.Euler(x, y + self.angle, z, 0)
        end
    end
end

--更新模型
function My:UpShowModel(state)
    for i,v in ipairs(self.parentList) do
        if i < 3 then
            v.gameObject:SetActive(state)
        end
    end
end

--初始化模型父物体
function My:InitParent()
    local Find = TransTool.Find
    local str = "Model/XBDZ_10_anim/Point003"
    self.parentList[1] = Find(self.root, str.."/equip2", self.Name)
    self.parentList[2] = Find(self.root, str.."/equip1", self.Name)
    self.parentList[3] = Find(self.root, str.."/equip3", self.Name)
end

--初始化模型路径
function My:InitModelPaths()
    local tempCfg = TreasureInfo:GetCfg(self.index)
    for i,v in ipairs(tempCfg) do
        if i > 9 and i < 14 then
            table.insert(self.modelNameList, v.modelPath)
        end
    end
end

--卸载模型
function My:UnloadModel()
    for i,v in ipairs(self.modelList) do
        UITreasure.AssetMgr.Instance:Unload(v.name, ".prefab", false)
      Destroy(v)
    end
    self.modelList = nil
end

--初始化道具
function My:InitItems(root, Find, CG, des)
    local str = "Model/XBDZ_10_anim/Point003/"
    for i=1, 13 do
        local path = str.."btns/"..i
        local box = Find(root, path, des)
        local it = ObjPool.Get(UIEquipRouletteIt)
        if self.cfgList[i] then it:Init(box, self.cfgList[i]) end
        table.insert(self.itList, it)

        if i < 11 then
            local path = str.."icons/"..i
            local tex = CG(Renderer, root, path)
            table.insert(self.iconList, tex)
        end
    end
end

--更新显示碰撞盒
function My:UpShowBox(state)
    for i,v in ipairs(self.itList) do
        v.go:SetActive(state)
    end
end

--更新显示贴图
function My:UpShowIcons(state)
    for i,v in ipairs(self.iconList) do
        v.gameObject:SetActive(state)
    end
end

--初始化贴图
function My:InitIcons()
    local list = self.texNameList
    local list1 = self.texScaleList
    for i,v in ipairs(list) do
        AssetMgr:Load(v, ObjHandler(self.SetIcons, self))
        self.iconList[i].transform.localScale = Vector3.one * list1[i]
    end
end

--设置贴图
function My:SetIcons(tex)
    self.texIndex = self.texIndex + 1
    self.iconList[self.texIndex].material.mainTexture = tex
end

--初始化贴图列表
function My:InitTexList(root, Find, des)
    local str = "awards/item"
    local tempCfg = TreasureInfo:GetCfg(self.index)
    local list = self:GetAwardCfgList()
    for i,v in ipairs(tempCfg) do
        if i > 10 and i < 14 then
            table.insert(self.cfgList, v)
        elseif i < 11 then
            local cfg = v
            for i1,v1 in ipairs(list) do
                if v1.type == i then
                    cfg = v1
                end
            end
            local key = tostring(cfg.iconId)
            local tex = ItemData[key].icon
            table.insert(self.texNameList, tex)
            table.insert(self.texScaleList, cfg.scale)
            table.insert(self.cfgList, cfg)
        end
    end
end

--获取需要根据等级变化的奖励列表
function My:GetAwardCfgList()
    local list = {}
    local tempCfg = TreasureInfo:GetCfg(self.index)
    for i,v in ipairs(tempCfg) do
        if #v.lv > 0 then
            local low = v.lv[1]
            local max = v.lv[2]
            local level = User.MapData.Level
            if level >= low and level <= max then
                table.insert(list, v)
            end
        end
    end
    return list
end

--更新
function My:Update()
    if self.isOpen then
        local it = UITreasure
        if it.curIndex == self.index then
            self.timer = self.timer + Time.deltaTime
            if self.timer >= self.animTime then
                self:StopAnim()
            else
                if self.timer <= self.ShakeTime then
                    it:CameraShakeEff(6)
                end
            end
        end
    end
end

--更新特效
function My:UpEff(state)
    self.buyEff1:SetActive(state)
    self.buyEff2:SetActive(state)
    self.buyEff3:SetActive(state)
    self.idleEff1:SetActive(not state)
    self.idleEff2:SetActive(not state)
    self:UpShowIcons(not state)
    self:UpShowBox(not state)
    self:UpShowModel(not state)
end

--播放动画
function My:PlayAnim()
    if UITreasure.curIndex == self.index then
        self.isOpen = true
        self:UpEff(true)
        self.anim:CrossFade("XBDZ_10_idle02")
        UITreasure:UpMaskBox(true)
    end
end

--停止动画
function My:StopAnim()
    self.anim:Stop("XBDZ_10_idle02")
    self.anim:CrossFade("XBDZ_10_idle01")
    self:UpEff(false)
    self.timer = 0
    self.isOpen = false
    UITreasure:UpMaskBox(false)
    UITreasure:ResetPos()
    if UITreasure.curIndex == self.index then
        self.roule:OpenGetMenu()
    end
end

--设置监听
function My:SetLnsr(func)
    local mgr = TreasureMgr
    mgr.eUpWTreasLogs[func](mgr.eUpWTreasLogs, self.RespUpWTreasLogs, self)
    mgr.eUpSTreasLogs[func](mgr.eUpSTreasLogs, self.RespUpSTreasLogs, self)
    RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpGoldLab, self)
end

--响应更新世界装备寻宝日志
function My:RespUpWTreasLogs(wList, index)
    if index ~= self.index then return end
    local info = TreasureInfo
    local logs = (self.index == info.equip) and info.wTreasLogs or info.topWTreasLogs
    for i,v in ipairs(wList) do
        self.log:AddWLog(v.str, v.id)
        --世界寻宝日志上限时，删除多余日志
        if #logs > 50 then
            table.remove(logs, #logs)
            self.log:DelWLog()
        end
    end
end

--响应更新自身寻宝日志
function My:RespUpSTreasLogs(sList, index)
    self:UpKeyLab()
    if index ~= self.index then return end
    local info = TreasureInfo
    local logs = (self.index == info.equip) and info.sTreasLogs or info.topSTreasLogs
    for i,v in ipairs(sList) do
        self.log:AddSLog(v)
        --自身寻宝日志上限时，删除多余日志
        if #logs > 50 then
            table.remove(logs, #logs)
            self.log:DelSLog()
        end
    end
    self:UpLuckVal()
end

--更新元宝数量显示
function My:UpGoldLab(ty)
    local ra = RoleAssets
    self.scoreLab.text = tostring(ra.HontInteg)
    -- self.goldLab.text = tostring(ra.Gold)
    self.goldLab.text = tostring(ra.BindGold)
    if self.shop then
        if self.shop.go.activeSelf then
            self.shop:UpScoreLab(tostring(ra.HontInteg))
        end
    end
end

--初始化所有寻宝日志
function My:InitLogs()
    local info = TreasureInfo
    local wLogs = (self.index == info.equip) and info.wTreasLogs or info.topWTreasLogs
    local sLogs = (self.index == info.equip) and info.sTreasLogs or info.topSTreasLogs
    for i,v in ipairs(wLogs) do
        self.log:InitWLog(v.name, v.id)
    end
    for i,v in ipairs(sLogs) do
        self.log:InitSLog(v)
    end
end

--初始化货币
function My:InitGoldLab()
    local info = RoleAssets
    self.scoreLab.text = info.HontInteg
    -- self.goldLab.text = info.Gold
    self.goldLab.text = info.BindGold
    self:UpKeyLab()
end

--更新幸运值
function My:UpLuckVal()
    local info = TreasureInfo
    local cfg = GlobalTemp["26"]
    if cfg == nil then return end
    local val = (self.index == info.equip) and info.equipLuckVal or info.topLuckVal
    local str = string.format("%s/%s", val, cfg.Value2[2])
    self.slider.value = val / cfg.Value2[2]
    self.sliderLab.text = str
end

-- --初始化头像
-- function My:InitIcon()
--     if User.MapData.Sex == 0 then
--         self.icon.spriteName = "TX_01"
--     else
--         self.icon.spriteName = "TX_02"
--     end
-- end

--更新寻宝钥匙数量
function My:UpKeyLab()
    local num = (self.index==TreasureInfo.equip) and 14 or 95
    local list = GlobalTemp[tostring(num)].Value2
    local keys = ItemTool.GetNum(list[1])
    self.keyLab.text = keys
    self.keys = keys
end

--初始化模块
function My:InitModule(rouleTran, logTran)
    self.roule = ObjPool.Get(UIEquipRoulette)
    self.roule:Init(rouleTran, self.index)
    self.log = ObjPool.Get(UIEquipTreasLog)
    self.log:Init(logTran, self.index)
end

--点击临时仓库
function My:OnDepotClick()
    self.treasBag = self:OpenModule(self.treasBag, UIEquipTreasBag, self.treasBagTran)
    self:UpModelShow(false)
end

--点击积分商城
function My:OnShopClick()
    self.shop = self:OpenModule(self.shop, UIEquipTreasShop, self.shopTran)
    self:UpModelShow(false)
end

--打开模块
function My:OpenModule(it, menu, tran)
    if not it then
        it = ObjPool.Get(menu)
        it:Init(tran, self.index)
    end
    it:Show()
    return it
end

--更新模型显示
function My:UpModelShow(state)
    self.model:SetActive(state)
end

--点击帮助
function My:OnHelp()
    local key = (self.index==TreasureInfo.equip) and "13" or "14"
    UIComTips:Show(InvestDesCfg[key].des, Vector3(-235,-125,0))
end

--初始化钥匙贴图
function My:InitKeyTex()
    local num = (self.index==TreasureInfo.equip) and 14 or 95
    local list = GlobalTemp[tostring(num)].Value2
    local cfg = ItemData[tostring(list[1])]
    if cfg == nil then return end
    self.texName = cfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    if self.keyTex then
        self.keyTex.mainTexture = tex
    end
end

--更新红点
function My:UpRedDot()
    local isShow = false
    for k,v in pairs(PropMgr.tb3Dic) do
        isShow = true
        break
    end
    self.redDot:SetActive(isShow)
end

--清理缓存
function My:Clear()
    self.keys = 0
    self:UnloadModel()
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    AssetMgr:Unload(self.texName,false)
    ObjPool.Add(self.roule)
    self.roule = nil
    ObjPool.Add(self.log)
    self.log = nil
    ListTool.ClearToPool(self.itList)
    if self.shop then
        ObjPool.Add(self.shop)
        self.shop = nil
    end
    if self.treasBag then
        ObjPool.Add(self.treasBag)
        self.treasBag = nil
    end
    if self.texNameList then
        for i,v in ipairs(self.texNameList) do
            AssetMgr:Unload(v, false)
        end
    end
end

return My