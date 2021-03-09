--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-18 10:33:46
--=============================================================================

UIPropsItem = Super:New{Name = "UIPropsItem"}

local My = UIPropsItem

function My:Init()
  local des = self.Name
  local root = self.root
  self.go = root.gameObject
  local CG = ComTool.Get

  self.curLbl = CG(UILabel, root, "cur", des)
  self.nextLbl = CG(UILabel, root, "next", des)
  self.nameLbl = CG(UILabel, root, "lbl", des)
  self.bgSp = self.go:GetComponent(typeof(UISprite))
end

--设置当前属性
function My:SetCur(val)
  self.curLbl.text = tostring(val)
end

--设置下一属性
function My:SetNext(val)
  self.nextLbl.text = tostring(val)
end

--设置名称
function My:SetName(name)
  self.nameLbl.text = name
end

--设置背景显示
function My:SetBgShow(at)
  local fnBg = "font_bg_2"
  local ty = "ty_a19"
  local bg = ""
  if at == nil then at = true end
  if at == true then
    bg = ty
  else
    bg = fnBg
  end
  self.bgSp.spriteName = bg
end

function My:SetActive(at)
  if at == nil then at = false end
  self.go:SetActive(at)
end

function My:Dispose()
  TableTool.ClearUserData(self)
end

return My
