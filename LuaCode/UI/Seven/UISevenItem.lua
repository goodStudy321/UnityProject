--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-21 22:01:52
-- 七日登陆条目
--=========================================================================

UISevenItem = Super:New{Name = "UISevenItem"}

local My = UISevenItem


function My:Init(root)
  -- self.root = root
  local cfg, des = self.cfg, self.Name
  if cfg == nil then return end
  local CG, GetS = ComTool.Get, ComTool.GetSelf
  local FindC = TransTool.FindChild
  self.lab = CG(UILabel, root, "lab")
  self.mark = FindC(root, "mark", des)
  self.sprGo = FindC(root, "spr2", des)
  self.action = FindC(root, "Action", des)
  self.itemTran = TransTool.Find(root, "item", des)

  UITool.SetBtnSelf(root, self.OnClick, self, des)

  self:MarkState(false)
  self:InitLab(cfg.id)
  self:InitCell(self.itemTran, cfg.icon)
end

--初始化天数文本
function My:InitLab(id)
  self.lab.text = string.format("第%s天", id)
end

--已领取状态
function My:YetGet()
  self.sprGo:SetActive(true)
  self.action:SetActive(false)
end

--显示红点
function My:ShowAction()
  self.action:SetActive(true)
end

--初始化Cell
function My:InitCell(tran, id)
  self.cell = ObjPool.Get(UIItemCell)
  self.cell:InitLoadPool(tran, 0.8)
  self.cell:UpData(id)
end

--标记物体状态
function My:MarkState(state)
  self.mark:SetActive(state)
end

--val(number):1:不能领取,2:可领取,3:已领取
function My:Refresh(val)
  if val == 3 then
    self:YetGet()
  end
end

function My:OnClick()
  self.cntr:Switch(self)
end

function My:Dispose()
  self.cfg = nil
  self.cell:DestroyGo()
  ObjPool.Add(self.cell)
  self.cell = nil
end



return My
