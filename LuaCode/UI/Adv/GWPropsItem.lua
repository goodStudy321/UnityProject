GWPropsItem = Super:New{Name = "GWPropsItem"}

local My = GWPropsItem

function My:Init(root)
  local des = self.Name
  self.go = root.gameObject
  local CG = ComTool.Get
  local TFC = TransTool.FindChild

  self.curLbl = CG(UILabel, root, "lbl1", des)
  self.curProp = CG(UILabel,root,"cur",des)
  self.nextLbl = CG(UILabel, root, "lbl2", des)
  self.nextProp = CG(UILabel, root, "next", des)
  self.maxLab = CG(UILabel, root, "maxLab", des)
  self.arr = TFC(root, "arr", des)
  self.bgSp = self.go:GetComponent(typeof(UISprite))
end

--设置当前属性
function My:SetCur(val)
  self.curProp.text = "+"..tostring(val)
end

--设置下一属性
function My:SetNext(val)
  self.nextProp.text = "+"..tostring(val)
end

--设置名称
function My:SetName(name)
  self.curLbl.text = name
  self.nextLbl.text = name
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

--设置满级状态
function My:SetMaxState(isMax)
  self.maxLab.gameObject:SetActive(isMax)
  self.curLbl.gameObject:SetActive(not isMax)
  self.curProp.gameObject:SetActive(not isMax)
  self.nextLbl.gameObject:SetActive(not isMax)
  self.nextProp.gameObject:SetActive(not isMax)
  self.arr:SetActive(not isMax)
end

--设置满级文本
function My:SetMaxLab(name, val)
  self.maxLab.text = string.format("%s +%s", name, val)
end

function My:SetActive(at)
  if at == nil then at = false end
  self.go:SetActive(at)
end

function My:Dispose()
  TableTool.ClearUserData(self)
end

return My