--[[
使用、批量、丢弃
批量弹出界面
--]]
local AssetMgr=Loong.Game.AssetMgr
Deal={Name="Deal"}
local My=Deal

local propTip=nil
local equipTip=nil

local Panel=nil
local CloseBtn=nil
local Title=nil
local ReBtn=nil
local AddBtn=nil
local Input=nil
local ConfirmBtn=nil

local num=1
local dic = {}

function My:New(o)
	o=o or {}
	setmetatable(o,self)
	self.__index=self
	return o
end

function My:Init(trans)	
	self.trans=trans
	local TT=TransTool.FindChild	
	local CG=ComTool.Get
	Panel=TT(self.trans,"Panel").transform
	CloseBtn=TT(Panel,"CloseBtn")
	Title=CG(UILabel,Panel,"Title",self.Name,false)
	ReBtn=TT(Panel,"ReBtn")
	AddBtn=TT(Panel,"AddBtn")
	Input=CG(UIInput,Panel,"Input",self.Name,false)
	Input.value=tostring(num)
	ConfirmBtn=TT(Panel,"ConfirmBtn")
	EventDelegate.Add(Input.onChange,EventDelegate.Callback(self.OnCNum,self))

	local UG=UIEventListener.Get

	local ClickP=function(go) self:OnClickP(go)end
	UG(CloseBtn).onClick=ClickP
	UG(ReBtn).onClick=ClickP
	UG(AddBtn).onClick=ClickP
	UG(ConfirmBtn).onClick=ClickP

	--self:InitTip()	
end

function My:OnCNum()
	if StrTool.IsNullOrEmpty(Input.value) then return end
	if tonumber(Input.value) > PropMgr.tb.num then
		Input.value=tostring(PropMgr.tb.num)
	end
	if tonumber(Input.value) < 1 then
		Input.value = 1
	end 
	num = tonumber(Input.value)
end


function My:OnClickP(go)
	self.tb = PropMgr.tb
	if(go.name=="CloseBtn")then
		self:PanelState(false)
	elseif(go.name=="ReBtn")then
		if(num==1)then return end
		num=num-1
		Input.value=tostring(num)
	elseif(go.name=="AddBtn")then
		if(num==self.tb.num)then return end
		num=num+1
		Input.value=tostring(num)
	elseif(go.name=="ConfirmBtn")then
		TableTool.ClearDic(dic)
		if(num>self.tb.num or num<1)then UITip.Log("请重新输入")return end
		dic[tostring(self.tb.id)]=num
		PropMgr.ReqSell(dic)
		self:PanelState(false)
	end
end

function My:PanelState(isState)
	Panel.gameObject:SetActive(isState)
end

function My:Dispose()
	
end
