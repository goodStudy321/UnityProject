--[[
外观展示模型
]]
require("UI/ItemModel/DisplayFoot")  --4
require("UI/ItemModel/DisplayHead")  --3
require("UI/ItemModel/DisplayBubble") --2
require("UI/ItemModel/DisplayModel") --1

UIItemModel=UIBase:New{Name="UIItemModel"}
local My = UIItemModel
My.tp=nil
My.pos=nil
My.path=nil

function My.IsTrue(type_id)
	local tp,istrue,path = nil,nil,nil
	istrue,path = DisplayModel.IsTrue(type_id)
	if istrue==true then 
		tp=1
	else
		istrue,path = DisplayBubble.IsTrue(type_id)
		if istrue==true then
			tp=2
		else
			istrue,path = DisplayHead.IsTrue(type_id)
			if istrue==true then
				tp=3
			else
				istrue,path = DisplayFoot.IsTrue(type_id)
				tp=4
			end
		end
	end
	My.tp=tp
	My.path=path
	return istrue
end

function My:InitCustom()
	self.tg=nil
	if My.tp==1 then 
		self.tg=ObjPool.Get(DisplayModel)
		self.tg.idName="pos"
	elseif My.tp==2 then 
		self.tg=ObjPool.Get(DisplayBubble)
	elseif My.tp==3 then 
		self.tg=ObjPool.Get(DisplayHead)
	elseif My.tp==4 then 
		self.tg=ObjPool.Get(DisplayFoot)
	end
	local TF = TransTool.FindChild
	self.bg=TF(self.root,"bg").transform
	self.bg.localPosition = My.pos
	self.tg:Init(TF(self.bg,self.tg.Name))
	self.tg.path=My.path
	self.tg.go:SetActive(true)
	self.tg:LoadTex()
end

function My:DisposeCustom()
	My.tp=nil
	My.pos=nil
	My.path=nil
	if self.tg then ObjPool.Add(self.tg) self.tg=nil end
end

return My