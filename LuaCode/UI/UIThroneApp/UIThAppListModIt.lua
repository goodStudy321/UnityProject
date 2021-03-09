--[[
 	authors 	:Loong
 	date    	:2017-08-24 11:59:17
 	descrition 	:模型模块条目
--]]

local base = require("UI/Cmn/UIModItem")

UIThAppListModIt = UIModItem:New{Name = "UIThAppListModIt"}
local My = UIThAppListModIt

function My:Init(root)
  self.root = root
  local info = self.info
  local cfg = info.bCfg
  self.cfg = cfg
  local TFC = TransTool.FindChild
  local CG, des = ComTool.Get, self.Name
  --名称标签
  self.nameLbl = CG(UILabel, root, "name", des)
  --图标贴图
  self.iconTex = CG(UITexture, root, "icon", des)

  --高亮(选中时改变)
  self.hlGo = TFC(root, "hl", des)
  self.hlGo:SetActive(false)

  self.limitLab = CG(UILabel, root, "limitLab", des)

  --红点设置
  self.actionGo = TFC(root, "action", des)
  self.actionGo:SetActive(false)

  self.lockGo = TFC(root, "lock", des)

  self.nameLbl.text = cfg.name
  UITool.SetBtnSelf(root, self.OnClick, self)

  AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))

  self:SetLock()
end

function My:SetLock()
  local info = self.info
  self.lockGo:SetActive(info.lock)
end

--设置图标
function My:SetIcon(tex)
  self.iconTex.mainTexture = tex
  self.texName = tex.name
end

--清理texture
function My:ClearIcon()
  if self.cfg then
    AssetMgr:Unload(self.cfg.icon,false)
  end
end

--点击条目按钮事件
function My:OnClick()
  local cntr = self.cntr
  if cntr.Switch then
    cntr:Switch(self)
  end
end

--激活
function My:SetActive(at)
  self:TweenPlay(at)
  base.SetActive(self, at,1)
end

--按钮选中效果
function My:TweenPlay(at)
  self.hlGo:SetActive(at)
end

--红点显隐效果
function My:IsShowAction(at)
  self.actionGo:SetActive(at)
end

function My:Dispose()
  self:ClearIcon()
  TableTool.ClearUserData(self)
end

return My
