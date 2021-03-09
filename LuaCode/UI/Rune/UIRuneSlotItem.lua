--[[
 	author 	    :Loong
 	date    	:2018-01-22 16:48:01
 	descrition 	:符文镶嵌槽条目
--]]

UIRuneSlotItem = Super:New{Name = "UIRuneSlotItem"}

local My = UIRuneSlotItem

function My:Init(root)
  self.root = root
  local des, CG = self.Name, ComTool.Get
  --槽索引
  self.idx = 0
  --有值时代表被嵌入
  self.info = nil
  --品质精灵
  self.qtSp = ComTool.GetSelf(UISprite, root, des)
  self.lvLbl = CG(UILabel, root, "lv", des)
  --贴图组件
  self.iconTex = CG(UITexture, root, "icon", des)
  --锁定对象
  self.lockLbl = CG(UILabel, root, "lock", des)

  local TFC = TransTool.FindChild
  self.flagGo = TFC(root,"flag",des)
  self.hlGo = TFC(root,"hl",des)
  self.hlGo:SetActive(false)
  self.addGo = TFC(root,"add",des)
  self.addGo:SetActive(false)
  self.lock = true
  UITool.SetLsnrSelf(root, self.OnClick, self, des, false)
end

--点击事件
function My:OnClick(go)
  if self.lock then
    UITip.Error("未解锁")
  else
    self.cntr:Switch(self)
  end
end

function My:SetIcon(tex)
  self.iconTex.mainTexture = tex
end

--设置品质
function My:SetQual(qt)
  self.qtSp.spriteName = UIRune.GetQuaPath(qt)
end

--设置被选中
function My:SetSelect(at)
  if at == nil then at = false end
  self.hlGo:SetActive(at)
end

--设置红点激活
function My:SetFlagActive(at)
  self.flagGo:SetActive(at)
end

function My:SetAddActive(at)
  self.addGo:SetActive(at)
end

--清理
function My:Clear()
  self.iconTex.mainTexture = nil
  self:SetQual(1)
  self.info = nil
end

--返回true 代表被镶嵌
function My:IsEmbedded()
  local res = (self.info and true or false)
  return res
end

function My:SetLv(info)
  if info == nil then return end
  local lv = info.lvCfg and info.lvCfg.lv
  local lvStr = nil
  if lv then lvStr = "Lv." .. lv end
  self.lvLbl.text = lvStr or ""
end

function My:SeyLockLbl(val)
  self.lockLbl.text = val
end

--设置锁定按钮的激活状态
function My:SetLockActive(at)
  if at == nil then at = true end
  self.lock = at
  self.lockLbl.gameObject:SetActive(at)
end

--通过符文信息进行刷新
--info(RuneInfo)
function My:RefreshByInfo(info)
  if info == nil then return end
  local cfg = info.cfg
  if cfg == nil then return end
  self.info = info
  self:SetLv(info)
  self:SetQual(cfg.qt)

  AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
end

--通过符文条目进行刷新
--item(UIRuneBagItem)
function My:RefreshByItem(item)
  if item == nil then return end
  local info = item.info
  self.info = info
  self:SetLv(info)
  self:SetQual(info.cfg.qt)
  self.iconTex.mainTexture = item.iconTex.mainTexture
end

function My:Dispose()
  if self.info and self.info.cfg then
    AssetMgr:Unload(self.info.cfg.icon, false)
  end
  self.cntr = nil
  self.lock = true
  self.info = nil
  self.idx = nil
  TableTool.ClearUserData(self)
end

return My
