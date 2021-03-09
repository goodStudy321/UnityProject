--[[
道具批量使用
--]]
BatchUse=UIBase:New{Name="BatchUse"}
local My = BatchUse
local curNum=nil
My.eClose=Event()

function My:InitCustom()
	local CG=ComTool.Get
	local TF = TransTool.FindChild
	
	self.Cell=ObjPool.Get(Cell)
	self.Cell:InitLoadPool(self.root,0.8,nil,nil,nil,Vector3.New(3.9,10.8,0))
	self.NameLab=CG(UILabel,self.root,"Name",self.Name,false)
	self.Slider=CG(UISlider,self.root,"Slider",self.Name,false)
	self.NumLab=CG(UILabel,self.Slider.transform,"Thumb/Num",self.Name,false)

	local U=UITool.SetBtnClick
	U(self.root,"AddBtn",self.Name,self.AddBtn,self)
	U(self.root,"ReduceBtn",self.Name,self.ReduceBtn,self)
	U(self.root,"Cancel",self.Name,self.Cancel,self)
	U(self.root,"Confirm",self.Name,self.Confirm,self)
	U(self.root,"CloseBtn",self.Name,self.Close,self)

	EventDelegate.Add(self.Slider.onChange,EventDelegate.Callback(self.OnCNum,self))
end

function My:UpData(item)
	self.item=item
	self.type_id=item.id
	self.maxNum=PropMgr.TypeIdByNum(self.type_id)
	curNum=self.maxNum
	self.Cell:UpData(self.item)
	self.NameLab.text=self.item.name

	self.NumLab.text=tostring(curNum)
	self.Slider.value=curNum/self.maxNum
end

function My:Cancel()
	self:Close()
	My.eClose()
end

function My:Confirm()
	if self.item.uFx==27 then 
		if curNum==1 then 
			OffRwdMgr.UseOffItem(self.type_id)
		else
			local can=OffRwdMgr.getCardNum(self.type_id)
			if can==0 then
				OffRwdMgr.UseOffItem(self.type_id)
			elseif can<curNum then 
				curNum=can
				MsgBox.ShowYes("最多可使用"..can.."个挂机卡",self.UseCb,self)
			else
				self:UseCb()
			end
		end	
	elseif self.item.uFx==26 then 
		local buffId = User:GetBuffIdBySrID(204)
		if buffId ~=0 and buffId ~= self.item.uFxArg[1] then
			MsgBox.ShowYesNo(string.format("已有经验药效果，是否使用%s替换？（替换后经验加成时间将重新计算）", self.item.name), self.UseCb, self, "确定")
		else
			self:UseCb()
		end
	elseif 	self.type_id==35212 then 
		self:BagUse()
	else
		self:UseCb()
	end

	My.eClose()
	self:Close()
end

function My:BagUse()
	MsgBox.ShowYesNo("是否花费"..self.item.uFxArg[1]*curNum.."元宝开启该礼包？",self.UseCb,self)
end

function My:UseCb()
	PropMgr.ReqUse(self.type_id,curNum,1)
end

function My:AddBtn()
	if(curNum==self.maxNum)then return end
	curNum=curNum+1
	self:ShowNUm()
end

function My:ReduceBtn()
	if(curNum==1)then return end
	curNum=curNum-1
	self:ShowNUm()
end

function My:OnCNum()
	--curNum = math.floor(self.Slider.value*self.maxNum)
	curNum = math.floor(self.Slider.value*self.maxNum)
	if curNum<1 then curNum=1 end
	self.NumLab.text=tostring(curNum)
end

function My:ShowNUm()
	self.NumLab.text=tostring(curNum)
	self.Slider.value=curNum/self.maxNum
end


function My:CloseCustom()
	if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) self.Cell=nil end
	self.Slider.value=0
	self.Slider.onChange=nil
end

return My