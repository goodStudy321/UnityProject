--[[
 	author 	    :Loong
 	date    	:2017-12-12 14:39:43
 	descrition 	:
--]]
require("UI/AssetItem")
UITop = UIBase:New{Name = "UITop"}

local My = UITop
My.isClick=false
local ts = tostring
local mathToStr = math.NumToStrCtr

function My:InitCustom()
  local root = self.root
  local name = self.Name
  local U = UITool.SetBtnClick
  if not self.dic then self.dic={} end
  self.grid=ComTool.Get(UIGrid,root,"Grid",self.Name,false)
  self.pre=TransTool.FindChild(root,"pre")
  self:SetEvent("Add")
end

function My:SetEvent(fn)
  RoleAssets.eUpAsset[fn](RoleAssets.eUpAsset,self.PropChg,self);
  TopMgr.eCloseTop[fn](TopMgr.eCloseTop,self.CloseTop,self)
  AssetItem.eClick[fn](AssetItem.eClick,self.OnClick,self)
end

--关闭界面
function My:CloseTop()
  self:Close()
end

function My:PropChg(ty)
  local item = self.dic[tostring(ty)]
  if item then
    item:ShowLab(ty)
  end
end

function My:OnClick(temp)
  GetWayFunc.SetJump(self.uiName,self.tp)
  QuickUseMgr.Jump(temp.uiName,temp.b,nil,nil,true)
end

function My:UpData(uiName,tp)
  self.uiName=uiName
  self.tp=tp
  TableTool.ClearDicToPool(self.dic)
  local id=nil
  if tp then
    id=string.format( "%s_%s",uiName,tp)
  else
    id=uiName
  end
  local temp = TopData[id]
  if not temp then return end
  local idList = temp.idList
  for i,v in ipairs(idList) do
    if LuaTool.IsNull(self.pre) then return end
    local go = GameObject.Instantiate(self.pre)
    go:SetActive(true)
    local trans = go.transform
    trans.parent=self.grid.transform
    trans.localScale = Vector3.one
    trans.localPosition=Vector3.zero
    local item = ObjPool.Get(AssetItem)
    item:Init(go)
    item:UpData(v)
    self.dic[tostring(v)]=item
  end
  self.grid:Reposition()
end

function My:DisposeCustom()
  self:SetEvent("Remove")
  TableTool.ClearDicToPool(self.dic)
  self.dic=nil
end


return My
