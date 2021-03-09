--[[
 	author 	    :Loong
 	date    	:2018-01-22 12:28:39
 	descrition 	:UI符文背包条目
  需要传入符文ID和对应的符文等级ID
--]]

require("UI/Rune/UIRuneItem")

local base = UIRuneItem
UIRuneBagItem = UIRuneItem:New{Name = "UIRuneBagItem"}

local My = UIRuneBagItem

--通过符文基础ID进行初始化
--id(number):符文基础ID
--root(Transform):根结点
function My:InitByID(id, root)
  local cfg = RuneCfg[tostring(id)]
  if id == nil then return end
  local lvID = id
  local lvCfg = BinTool.Find(RuneLvCfg, lvID)
  if lvCfg == nil then return end
  self.cfg = cfg
  self.lvCfg = lvCfg
  self:Init(root)
end

function My:InitCustom()
  local des = self.Name
  local root = self.root
  local CG = ComTool.Get
  --属性标签
  self.propLbl = CG(UILabel, root, "prop", des)
  --评分标签
  self.scoreLbl = CG(UILabel, root, "score", nil)
  -- local hasTran = root:Find("hasd")
  -- if hasTran then self.hasdGo = hasTran.gameObject end
  self.hasdSp = CG(UISprite, root, "hasd", des)
  self.hasdSp.gameObject:SetActive(false)

  AssetMgr:Load(self.cfg.icon, ObjHandler(self.SetIcon, self))
  local cfg = self.cfg
  local lvCfg = self.lvCfg
  self:SetLv(cfg, lvCfg)
  self:SetName(cfg.name)
  self:SetQual(cfg.qt)
  self.propLbl.text = self:GetPropStr(cfg, lvCfg)
  if self.scoreLbl then self.scoreLbl.text = "评分:" .. lvCfg.score end
  self.isSelect = false
end

function My:SetSelect(at)
  base.SetSelect(self, at)
  self.isSelect = at
end

--2:更高品质,1:已有属性,0:无
function My:SetHased(op)
  op = op or 0
  if op == 0 then
    self.hasdSp.gameObject:SetActive(false)
  else
    self.hasdSp.gameObject:SetActive(true)
    self.hasdSp.spriteName = ( op < 2 and "fw_info" or "fw_better")
  end
end

--刷新
function My:Refresh()
  local cfg = self.cfg
  local lvCfg = self.lvCfg
  self:SetLv(cfg, lvCfg)
  self.propLbl.text = self:GetPropStr(cfg, lvCfg)
end

function My:DisposeCustom()
  AssetMgr:Unload(self.cfg.icon, false)
  self.cfg = nil
  self.info = nil
  self.lvCfg = nil
end

return My
