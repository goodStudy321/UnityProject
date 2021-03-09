--[[
 	author 	    :Loong
 	date    	:2018-01-22 12:28:39
 	descrition 	:UI符文条目
--]]

UIRuneItem = Super:New{Name = "UIRuneItem"}

local My = UIRuneItem

function My:Init(root)
  local des = self.Name
  self.root = root
  self.go = root.gameObject
  local CG = ComTool.Get

  --等级标签
  self.lvLbl = CG(UILabel, root, "lv", des)
  --名称标签
  self.nameLbl = CG(UILabel, root, "name", des)
  --图标贴图
  self.iconTex = CG(UITexture, root, "icon", des)
  --高亮精灵
  self.hlSp = ComTool.GetSelf(UISprite, root, des)
  --品质精灵
  self.qtSp = CG(UISprite, root, "bg", des)

  UITool.SetLsnrSelf(root, self.OnClick, self, des, false)
  self.kuangGo = TransTool.FindChild(root, "kuang", des)
  self:InitCustom()
end

function My:InitCustom()

end

--设置图标
function My:SetIcon(tex)
  if LuaTool.IsNull(self.iconTex) then return end
  self.iconTex.mainTexture = tex
end

--设置等级
function My:SetLv(cfg, lvCfg)
  local isExp = RuneMgr.IsExp(cfg)
  local lv = nil
  if isExp == true then
    lv = ""
  else
    lv = "Lv." .. tostring(lvCfg.lv)
  end
  self.lvLbl.text = lv
end

function My:SetName(name)
  self.nameLbl.text = name
end

function My:SetQual(qt)
  self.qtSp.spriteName = UIRune.GetQuaPath(qt)
end

function My:OnClick(go)
  local cntr = self.cntr
  if cntr == nil then return end
  cntr:Select(self)
end

--设置选中
function My:SetSelect(at)
  if at == nil then at = false end
  local sp = at and "ty_a15" or "ty_a4"
  if not self.hlSp then return end
  self.hlSp.spriteName = sp
  if at then
    self.kuangGo:SetActive(false)
  else
    self.kuangGo:SetActive(true)
  end
end

function My:SetActive(at)
  if at == nil then at = false end
  self.go:SetActive(at)
end

function My:Dispose()
  TableTool.ClearUserData(self)
  self:DisposeCustom()
  self.cntr = nil
end

--获取属性字符
--cfg:符文基础配置
--lvCfg:符文等级配置
function My:GetPropStr(cfg, lvCfg)
  local sb = ObjPool.Get(StrBuffer)
  local name, pCfg, str = nil
  local BF = BinTool.Find
  local GetVal = PropTool.GetVal
  if cfg.p1 then
    pCfg = BF(PropName, cfg.p1)
    name = pCfg and pCfg.name or "无:" .. cfg.p1
    str = GetVal(pCfg, lvCfg.v1)
    sb:Apd(name):Apd("："):Apd(str)
  else
    --sb:Apd(lvCfg.id):Apd(",无属性字段")
    sb:Apd("分解经验"):Apd("："):Apd(lvCfg.deExp)
  end
  pCfg, str = nil
  if cfg.p2 then
    pCfg = BF(PropName, cfg.p2)
    name = pCfg and pCfg.name or "无:" .. cfg.p2
    str = GetVal(pCfg, lvCfg.v2)
    sb:Apd("\n")
    sb:Apd(name):Apd("："):Apd(str)
  end
  local str = sb:ToStr()
  ObjPool.Add(sb)
  return str
end

function My:DisposeCustom()

end


return My
