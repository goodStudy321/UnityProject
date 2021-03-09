UIAdvGetWay = Super:New{Name = "UIAdvGetWay"}
local My = UIAdvGetWay

local GWI = require("UI/Adv/UIAdvGetWayItem")

--获取途径配置
My.getWayCfg = nil

--key:显示名称 v:WayItem
My.itDic = {}

function My:Init(root,cfg)
    self.root = root
    self.go = root.gameObject
    local name = self.Name
    local CG = ComTool.Get
    local USBC = UITool.SetBtnClick
    local TFC = TransTool.FindChild

    self.itGrid = CG(UIGrid,root,"Grid",name)
    self.itMod = TFC(root,"wayItem",name)
    self.itMod:SetActive(false)
    USBC(root, "bg/box", name, self.OnBoxClick, self)
    self:Refresh(cfg)
end

--cfg:获取途径的配置
function My:Refresh(cfg)
    if cfg == nil then return end
    if cfg == self.getWayCfg then return end
    self.getWayCfg = cfg
    self:SetItDic()
end

--设置图标字典
function My:SetItDic()
    local itGrid = self.itGrid
    local itGridTran = itGrid.transform
    local mod = self.itMod
    local itDic = self.itDic
    TableTool.ClearDicToPool(itDic)
    TransTool.RenameChildren(itGridTran)
    local getWayCfg = self.getWayCfg.wayDic
    if getWayCfg == nil or #getWayCfg <= 0 then return end
    local Inst = GameObject.Instantiate
    local TA = TransTool.AddChild
    local Get = ObjPool.Get
    for i,v in pairs(getWayCfg) do
        local trans = itGridTran:Find("none")
        local it = nil
        if trans == nil then
            it = Inst(mod)
            trans = it.transform
        else
            it = trans.gameObject
        end
        it.name = v.k
        it:SetActive(true)
        TA(itGridTran,trans)
        local it = Get(GWI)
        it:Init(trans)
        it:GetWayName(v.v)
        itDic[i] = it
    end
    itGrid:Reposition()
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

--点击碰撞器
function My:OnBoxClick()
    self:Close()
end

function My:Dispose()
    self.getWayCfg = nil
    TableTool.ClearDicToPool(self.itDic)
end

return My