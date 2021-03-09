--[[
道具出售设置价格
--]]
PricePanel = UIBase:New{Name="PricePanel"};
local My = PricePanel;
My.winCtrl = {};

My.eClear = Event();
My.eNum = Event();
My.eConfirm = Event();

function My:InitCustom()
	My.winCtrl.trans = self.root;

	local TF = TransTool.FindChild;

	UITool.SetBtnClick(My.winCtrl.trans,"Close",self.Name,self.ClickY,self)
	local grid = TF(My.winCtrl.trans,"Grid").transform
	for i=0,9 do
		local btn=TF(grid,tostring(i))
		UITool.SetLsnrSelf(btn,self.ClickNum,self,self.Name)
	end

	UITool.SetBtnClick(grid,"C",self.Name,self.ClickC,self)
	UITool.SetBtnClick(grid,"Y",self.Name,self.ClickY,self)

	self:SetPos(Vector3.New(64.6,-120.4,0))

	self.num = "0"
end

function My:SetPos(pos)
	self.root.localPosition=pos
end

function My:ClickNum(go)
	My.eNum(go.name)
	if self.num == "0" then
		self.num = go.name
	else
		self.num = self.num .. go.name
	end
end

function My:ClickC()
	self.num = "0"
	My.eClear()
end

function My:ClickY()
	My.eConfirm(tonumber(self.num))
	self:Close()
end

function My:OpenCustom()
	
end

function My:CloseCustom()
	self.num = "0"
end

return My;