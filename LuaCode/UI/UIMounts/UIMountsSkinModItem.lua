--[[
 	authors 	:Loong
 	date    	:2017-08-21 01:35:26
 	descrition 	:皮肤预览条目
--]]

UIMountsSkinModItem = Super:New{Name = "UIMountsSkinModItem"}
local My = UIMountsSkinModItem
My.root = nil

--配置信息
My.info = nil

--模型
My.mod = nil

--容器
My.cntr = nil

--名称标签
My.nameLbl = nil

--标题标签
My.titleLbl = nil

--高亮(选中时改变)
My.hlGo = nil

function My:Init()
  local info = self.info
  local root = self.root
  local CG = ComTool.Get
  local des = self.Name
  self.nameLbl = CG(UILabel, root, "name", des)
  self.titleLbl = CG(UILabel, root, "title", des)
  self.hlGo = TransTool.FindChild(root, "hl", des)
  self.hlGo:SetActive(false)

  UITool.SetBtnSelf(root, self.OnClick, self)
  self.nameLbl.text = info.name

  self:SetTitle()
  self:LoadMod()
end

function My:SetTitle()
  local info = self.info
  if info.lock then
    self.titleLbl.text = "未解锁"
  else
    self.titleLbl.text = UIMisc.GetStepStr(info.cfg.st)
  end
end

--点击条目按钮事件
function My:OnClick()
  local cntr = self.cntr
  if cntr.cur == self then return end
  if cntr.cur ~= nil then
    cntr.cur:SetActive(false)
  end
  self:SetActive(true)
  cntr.cur = self
  cntr.cntr:Switch(self.info)
end

--激活
function My:SetActive(at)
  self:TweenPlay(at)
  if self.mod == nil then return end
  self.mod:SetActive(at)
end

--按钮选中效果
function My:TweenPlay(at)
  self.hlGo:SetActive(at)
end

--加载模型
function My:LoadMod()
  local modID = self.info.uMod
  AssetTool.LoadMod(modID, self.LoadModCb, self)
end

--加载模型回调
function My:LoadModCb(gbj)
  self.mod = gbj
  self.cntr:AddMod(self, gbj)
end

function My:Dispose()
  local mod = self.mod
  if mod then
    AssetMgr:Unload(mod.name, ".prefab", false)
  end
  self.mod = nil
end
