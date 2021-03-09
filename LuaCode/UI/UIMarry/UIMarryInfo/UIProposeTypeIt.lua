--[[
 	authors 	:Liu
 	date    	:2018-12-13 19:30:00
 	descrition 	:提亲类型面板项
--]]

UIProposeTypeIt = Super:New{Name = "UIProposeTypeIt"}

local My = UIProposeTypeIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find


    local parent = Find(root, "awardLab/Grid", des)
    local coinSpr = CG(UISprite, root, "priceBg/spr")

    self.priceLab = CG(UILabel, root, "priceBg/priceLab")
    self.countLab = CG(UILabel, root, "countLab/lab")
    self.friendlyLab = CG(UILabel, root, "countLab/lab1")
    self.tex = CG(UITexture, root, "titleLab/tex")

    self.countLab.transform.localPosition = Vector3.New(51,0,0)
    self.friendlyLab.gameObject:SetActive(false)

    self.cellList = {}
    self.cfg = cfg
    self.isInit = false

    self:InitSpr(cfg, coinSpr)
    self:InitCell(cfg, parent)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    UIMarryInfo.eSHow[func](UIMarryInfo.eSHow, self.RespShow, self)
end

--响应显示界面
function My:RespShow(index)
    if index == 2 and not self.isInit then
        self:UpLab()
        self.isInit = true
    end
end

--更新文本
function My:UpLab()
    local cfg = self.cfg
    local key = tostring(cfg.titleId)
    local tCfg = TitleCfg[key]
    if tCfg == nil then return end
    local str1 = string.format("婚礼次数：%s次", cfg.feastCount)
    self.priceLab.text = cfg.goldCount
    self.countLab.text = str1
    self.friendlyLab.text = "所需亲密度："..cfg.friendly
    --self.texName1 = tCfg.prefab1..".png"
    self.texName1 = string.sub(tCfg.prefab1,1,-5)..".png"
    AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon, self))
end

--设置称号
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--初始化贴图
function My:InitSpr(cfg, coinSpr)
    local type = cfg.goldType
    if type == 2 then
        coinSpr.spriteName = "money_02"
    elseif type == 3 then
        coinSpr.spriteName = "money_03"
    end
end

--初始化Cell
function My:InitCell(cfg, tran)
    for i,v in ipairs(cfg.award) do
        local it = ObjPool.Get(UIItemCell)
        it:InitLoadPool(tran, 0.65)
        it:UpData(v.k, v.v)
        table.insert(self.cellList, it)
    end
end

--清理缓存
function My:Clear()
    self.isInit = false
    AssetMgr:Unload(self.texName1,false)
    self.texName1 = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
    self:SetLnsr("Remove")
end

return My