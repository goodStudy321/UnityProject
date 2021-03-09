--[[
 	author 	    :Loong
 	date    	:2018-01-25 19:39:54
 	descrition 	:UI符文合成条目
--]]

UIRuneComItem = Super:New{Name = "UIRuneComItem"}

local My = UIRuneComItem

function My:Init(root, cntr)
  local des = self.Name
  --拥有数量
  self.num = 0
  --符文基础配置
  --self.cfg = nil
  self.root = root
  self.cntr = cntr
  local CG = ComTool.Get
  --名称标签
  self.nameLbl = CG(UILabel, root, "name", des)
  --数量标签
  self.numLbl = CG(UILabel, root, "num", des)
  --图标贴图
  self.iconTex = CG(UITexture, root, "icon", des)
  --品质精灵
  self.qtSp = ComTool.GetSelf(UISprite, root, des)

  UITool.SetLsnrSelf(root, self.OnClick, self, des, false)

  self:Clear()
end

function My:SetIcon(tex)
  self.iconTex.mainTexture = tex
end

--根据拥有数量设置标签
function My:SetNumber()
  local id = self.cfg.id
  local num = RuneMgr.GetCountByID(id)
  self.num = num
  local str = (num < 1 and "[f21919]" or "[f4ddbd]")
  str = str .. num
  if num < 1 then
    str = str .. "[f4ddbd]/1"
  else
    str = str .. "/1"
  end
  self.numLbl.text = str
end

--直接设置数量标签
function My:SetNumLbl(text)
  self.numLbl.text = text
end

--设置可以最大可以合成的数量
function My:SetMaxNum(lhs, rhs)
  local GetCount = RuneMgr.GetCountByID
  local own = GetCount(self.cfg.id)
  local lhsNum = GetCount(lhs.cfg.id)
  local rhsNum = GetCount(rhs.cfg.id)
  local max = (lhsNum < rhsNum and lhsNum or rhsNum)
  local str = max .. "/" .. own
  self.numLbl.text = str
end

--返回true:数量足够
function My:CheckNumber()
  if self.num < 1 then
    return false
  else
    return true
  end
end

--刷新
--id(number):合成ID即基础ID
function My:RefreshByID(id)
  local cfg = self.cfg
  if (not cfg) or ( cfg and (cfg.id ~= id)) then
    local lastCfg = cfg
    cfg = RuneCfg[tostring(id)]
    AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
    self.nameLbl.text = cfg.name
    self.qtSp.spriteName = UIRune.GetQuaPath(cfg.qt)
    self.cfg = cfg
    --local uFxArg = id * 1000 + 1
    --self.itCfg = ItemTool.GetByuFxArg(uFxArg)
    if lastCfg then AssetMgr:Unload(lastCfg.icon, false) end
  end
  --self:SetNumber()
end

--通过道具ID刷新
--id(number):道具ID
function My:RefreshByItemID(id)
  local cfg = ItemData[tostring(id)]
  self.itCfg = cfg
  AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
  self.nameLbl.text = cfg.name
  self.qtSp.spriteName = UIRune.GetQuaPath(cfg.quality)
end

function My:OnClick()
  if self.itCfg then
    UIMgr.Open(PropTip.Name, self.ShowTip, self)
  elseif self.cfg then
    local cntr = self.cntr
    if cntr and cntr.OnClickItem then
      cntr:OnClickItem(self)
    end
  end
end

function My:ShowTip(name)
  local ui = UIMgr.Get(name)
  local id = self.itCfg.id
  ui:UpData(tostring(id))
end

function My:Clear()
  self.numLbl.text = ""
  self.nameLbl.text = ""
  self.iconTex.mainTexture = nil
  self.qtSp.spriteName = UIRune.GetQuaPath(1)
end

function My:UnloadCfgIcon()
  if self.cfg then
    AssetMgr:Unload(self.cfg.icon, false)
  end
end

function My:UnloadItCfgIcon()
  if self.itCfg then
    AssetMgr:Unload(self.itCfg.icon, false)
  end
end

function My:Dispose()
  self:UnloadCfgIcon()
  self:UnloadItCfgIcon()
  self.cfg = nil
  self.itCfg = nil
  TableTool.ClearUserData(self)
end


return My
