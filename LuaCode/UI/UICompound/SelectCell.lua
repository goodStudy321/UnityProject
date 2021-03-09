--[[
选择装备格子
--]]
SelectCell=Super:New{Name="SelectCell"}
local My = SelectCell

function My:Init(go)
	self.trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild 

	self.bg=CG(UISprite,self.trans,"bg",self.Name,false)
	self.select=CG(UIToggle,self.trans,"select",self.Name,false)
	self.NameLab=CG(UILabel,self.trans,"Name",self.Name,false)
	self.Cell=ObjPool.Get(Cell)
	self.Cell:InitLoadPool(self.trans,0.8,nil,nil,nil,Vector3.New(-84.7,0,0))
	--UITool.SetBtnSelf(self.select.gameObject,self.OnSelect,self,self.Name)
end

function My:UpData(tb,i)
	self.id=tb.id
	local item = ItemData[tostring(tb.type_id)]
	if(item==nil)then iTrace.Error("xiaoyu","道具表为空 type_id:".. tb.type_id)return end	
	self.Cell:UpData(item)	
	self.NameLab.text=item.name
end

function My:Dispose()
	if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) end
	GameObject.Destroy(self.trans.gameObject)
end