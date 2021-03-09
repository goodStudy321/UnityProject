--[[
 	authors 	:Loong
 	date    	:2017-08-24 11:59:17
 	descrition 	:模型模块条目
--]]

local base = require("UI/Cmn/UIModItem")

UIListModItem = UIModItem:New{Name = "UIListModItem"}
local My = UIListModItem

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
  if cfg then
    self.nameLbl.text = cfg.name
  end
  UITool.SetBtnSelf(root, self.OnClick, self)

  AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))

  self:SetLock()
end

function My:SetLock()
  local info = self.info
  self.lockGo:SetActive(info.lock)
  local isLock = info.lock
  local birLv = self.cfg.rLv
  local limitStr = ""
  local birthLvC = UIMisc.ToNum(birLv)
  local curBirthLv = User.MapData.ReliveLV
  if isLock == true and curBirthLv >= birLv then
    limitStr = "未激活"
  elseif isLock == true and curBirthLv < birLv then
    limitStr = string.format("%s转激活",birthLvC)
  elseif isLock == false then
    limitStr = ""
  end
  self.limitLab.text = limitStr
end

--设置图标
function My:SetIcon(tex)
  if LuaTool.IsNull(self.iconTex) then
    return
  end
  self.iconTex.mainTexture = tex
  self.texName = tex.name
end

--清理texture
function My:ClearIcon()
  if self.cfg then
    -- iTrace.Error("GS","皮肤列表资源释放===",self.cfg.icon)
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
  base.SetActive(self, at)
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
