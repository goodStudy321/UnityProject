--[[
 	authors 	:Loong
 	date    	:2017-08-25 16:07:22
 	descrition 	:UI飘字
--]]

require("UI/Tween/UITweenDigtalFlyItem")
UITweenDigtalFly = Super:New{Name = "UITweenDigtalFly"}


local My = UITweenDigtalFly
local GBJ = UnityEngine.GameObject

My.root = nil

--模板
My.model = nil

--条目名称
My.modelName = "item"

function My:Ctor()
  --条目列表
  self.items = {}
end

function My:Init()
  local root = self.root
  self.model = root:Find(self.modelName).gameObject
  self.model:SetActive(false)
end

--发射 arg:数字
function My:Launch(arg)
  if self.model == nil then return end
  arg = tostring(arg)
  local item = nil
  if #self.items == 0 then
    local go = GBJ.Instantiate(self.model)
    item = UITweenDigtalFlyItem:New{}
    local trans = go.transform
    trans.parent = self.root
    trans.localPosition = Vector3.zero
    trans.localScale = Vector3.one
    item.cntr = self
    item.go = go
    item:Init()
  else
    item = table.remove(self.items)
  end
  item:Launch(arg)

end
