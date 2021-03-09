--=================================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-08 22:16:17
-- 道具条目基类:具有如下属性:
-- 点击OnClick(调用容器Switch方法);图标;品质;数量;设置选中(SetSelect)
--=================================================================================

UIItem = Super:New{Name = "UIItem"}

local My = UIItem


--初始化
function My:Init(root)
  self.root = root
  local des = self.Name
  local CG = ComTool.Get
  self.numLbl = CG(UILabel, root, "num", des)
  self.iconTex = CG(UITexture, root, "icon", des)
  self.qtSp = ComTool.GetSelf(UISprite, root, des)
  UITool.SetBtnSelf(root, self.OnClick, self, des)
  local hlTran = root:Find("hl")
  if hlTran then self.hlGo = hlTran.gameObject end
  self:SetProp()
end

--设置品质
function My:SetQual()
  local cfg = self.cfg
  local qt = cfg and cfg.quality or 0
  self.qtSp.spriteName = UIMisc.GetQuaPath(qt)
end

--设置数量
function My:SetNumber()
  local num = ItemTool.GetNum(self.cfg.id)
  self.numLbl.text = tostring(num)
end

--加载图标
function My:LoadIcon()
  -- if self.icon == self.cfg.icon then return end
  self.icon = self.cfg.icon
  local CB = ObjHandler(self.SetIcon, self)
  AssetMgr:Load(self.icon, CB)
end

--设置图标
function My:SetIcon(tex)
  if LuaTool.IsNull(self.iconTex) then return end
  self.iconTex.mainTexture = tex
end

--刷新
function My:Refresh()
  if self.cfg == nil then return end
  self:SetNumber()
end

function My:RefreshByID(id)
  self.cfg = ItemData[tostring(id)]
  self:SetProp()
end

function My:RefreshByCfg(cfg)
  self.cfg = cfg
  self:SetProp()
end

function My:SetProp()
  if self.cfg == nil then return end
  self:SetQual()
  self:LoadIcon()
  self:SetNumber()
end

--点击事件
function My:OnClick()
  local cntr = self.cntr

  if cntr == nil or cntr.Switch == nil then
    self:OpenTip()
    return 
  end
  cntr:Switch(self)
end

function My:OpenTip()
  local it = self.root
  local qtSp = self.qtSp
  PropTip.pos = it.transform.position
  PropTip.width = qtSp.width
  UIMgr.Open("PropTip", self.ShowTip, self)
end

function My:ShowTip(name)
  local ui = UIMgr.Get(name)
  local id = self.cfg.id
  ui:UpData(id)
end

function My:SetSelect(at)
  at = at or false
  local hlGo = self.hlGo
  if hlGo == nil then return end
  hlGo:SetActive(at)
end

function My:ClearIcon()
  if self.cfg then
    -- iTrace.Error("GS","uiitem  资源释放===",self.cfg.icon)
    AssetMgr:Unload(self.cfg.icon,false)
  end
end

function My:Dispose()
  self:ClearIcon()
  TableTool.ClearUserData(self)
  self.cfg = nil
end

return My
