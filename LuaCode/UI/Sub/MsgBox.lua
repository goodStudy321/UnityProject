--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017/6/16 21:14:02
-- ShowYes 显示Y
-- ShowYesNo 显示Y/N
-- 注意
-- 1.关闭时是否需要处理Y/N回调,可通过SetCloseOpt方法设置CloseOpt(MsgBoxCloseOpt)选项
-- No:走N回调,Yes:走Y回调,None无
--=============================================================================



MsgBox = UIBase:New{Name = "MsgBox"}
local My = MsgBox

--按钮宽度
My.btnWidth = 100

--消息
My.msg = ""

--否信息
My.noStr = ""

--是信息
My.yesStr = ""

--否按钮回调
My.noCb = Event()

--是按钮回调
My.yesCb = Event()
--状态按钮回调
My.togCb = Event()
--true:持续显示
My.conDisplay = false

My.seconds = nil
--关闭选项
MsgBoxCloseOpt = {None=0,Yes=1,No=2}

--关闭时 No:走N回调,Yes:走Y回调,None无
My.CloseOpt = MsgBoxCloseOpt.None

--居中之类设置
My.alignment=nil;

--// LY add begin
My.willCloseWnd = false;
My.tempShowData = nil;
--// LY add end

My.isClose=true

--设置是按钮位置
function My:SetYesPos()
	local pos = self.bg.transform.localPosition
	pos:Set(pos.x, self.yesBtn.transform.localPosition.y, 0)
	pos.x = pos.x - (self.btnWidth * 0.05)
	self.yesBtn.transform.localPosition = pos
end

--设置是/否按钮位置
function My:SetYesNoPos()
	local interval = (self.bg.width - (self.btnWidth * 2)) / 3
	local pos = self.bg.transform.localPosition
	local offset = (self.btnWidth + interval) * 0.5
	pos:Set(pos.x, self.yesBtn.transform.localPosition.y, 0)
	pos.x = pos.x - offset
	self.noBtn.transform.localPosition = pos

	pos.x = self.bg.transform.localPosition.x
	pos.x = pos.x + offset
	self.yesBtn.transform.localPosition = pos
end

--点击否按钮
function My:ClickNoBtn()
	My.willCloseWnd = true;
	self:HandleNo()
	self:Close()
end

--点击是按钮
function My:ClickYesBtn()
	My.willCloseWnd = true;
	self:HandleYes()
	if My.isClose~=false then self:Close() end
end


function My:HandleNo()
	EventMgr.Trigger("MsgBoxClickNo")
	My.noCb()
	self:ClearLsnr()
end

function My:HandleYes()
	EventMgr.Trigger("MsgBoxClickYes")
	My.yesCb()
	if My.isClose~=false then self:ClearLsnr()end
end


--设置按钮宽度
function My:SetBtnWidth()
	local yesSprite = self.yesBtn:GetComponent(typeof(UISprite));
	if LuaTool.IsNull(yesSprite) then
		iTrace.Error("Loong", self.Name, "yesBtn no UISprite")
	else
		self.btnWidth = yesSprite.width;
	end
end

function My:InitCustom()
	local msg = "消息框"
	local root = self.root
	local CG = ComTool.Get
	local TFC = TransTool.FindChild
    local UC = UITool.SetLsnrClick
	self.bg = CG(UISprite, root, "bg", msg)
	local tran = self.bg.transform
	self.msgLbl = CG(UILabel, root, "msg", msg)
	self.noBtn = CG(UIButton, tran, "noBtn", msg)
	self.noLbl = CG(UILabel, tran, "noBtn/Label", msg)
	self.yesBtn = CG(UIButton, tran, "yesBtn", msg)
	self.yesLbl = CG(UILabel, tran, "yesBtn/Label", msg)
	self.togLbl=CG(UILabel,tran,"togBack/Label",msg)
	self.togBack=CG(UIToggle,tran,"togBack",msg)
	self.togBackGo=self.togBack.gameObject
	self:SetBtnWidth()
	local ED = EventDelegate
	local EDCB = ED.Callback
	local Add1 = ED.Add
	Add1(self.noBtn.onClick, EDCB(self.ClickNoBtn, self))
	Add1(self.yesBtn.onClick, EDCB(self.ClickYesBtn, self))
	UITool.SetBtnClick(root, "CloseBtn", self.Name, self.OnClickClose, self)
	local EH = EventHandler
	local Add2 = EventMgr.Add
	Add2("MsgBoxYes", EH(self.SetYes, self))
	Add2("MsgBoxYesNo", EH(self.SetYesNo, self))
	Add2("MsgBoxConDisplay",EH(My.SetConDisplay))
end

function My:OpenCustom(  )
	self:SetTogState()
end

function My:SetTogState( )
	if My.TogMsg==nil then
		self.togBackGo:SetActive(false)
		return
	end
	local ED = EventDelegate
	local EDCB = ED.Callback
	local ES = ED.Set
	self.togBackGo:SetActive(true)
	My.togState=My.togState==true and true or false
	self.togBack.value=My.togState
	self.togLbl.text=My.TogMsg
	ES(self.togBack.onChange, EDCB(self.OnClickTog, self))
end

function My:OnClickTog(  )
	My.togCb(self.togBack.value)
end

function My:OnClickClose()
	local opt = My.CloseOpt
	if type(opt)~="number" then
		opt = MsgBoxCloseOpt.None
	elseif opt==MsgBoxCloseOpt.Yes then
		self:HandleYes()
	elseif opt==MsgBoxCloseOpt.No then
		self:HandleNo()
	end
	self:Close()
end

function My:CanRecords()
	do return false end
end


function My:ConDisplay()
	do return My.conDisplay end
end

function My.SetConDisplay(val)
	My.conDisplay = val
end

function My:ClearLsnr()
	My.noCb:Clear()
	My.yesCb:Clear()
	EventMgr.Trigger("MsgBoxClear")
	if My.timer then
		My.timer:Stop()
		My.timer:AutoToPool()
		My.timer = nil
	end
	My.seconds = nil
	My.SetCloseOpt(MsgBoxCloseOpt.None)
	My.conDisplay = false;
end

function My:CloseCustom()
	self:ClearLsnr()

	--// LY add bedin
	if  My.willCloseWnd == true and My.tempShowData ~= nil then
		My.willCloseWnd = false;

		if My.tempShowData.type == 1 then
			My.ShowYes(My.tempShowData.msg, My.tempShowData.yesCb, My.tempShowData.obj, My.tempShowData.yesStr, My.tempShowData.alignment);
		elseif My.tempShowData.type == 2 then
			My.ShowYesNo(My.tempShowData.msg, My.tempShowData.yesCb, My.tempShowData.yesObj, My.tempShowData.yesStr, My.tempShowData.noCb, My.tempShowData.noObj, My.tempShowData.noStr, My.tempShowData.second,
			 My.tempShowData.alignment,My.tempShowData.TogMsg,My.tempShowData.togCb,My.tempShowData.togObj,My.tempShowData.togState);
		end

		My.tempShowData = nil;
	end
	My.willCloseWnd = false;
	--// LY add end
end

function My:DisposeCustom()
	self:ClearLsnr()
end


function My.SetCloseOpt(opt)
	My.CloseOpt = opt
end

function My:SetYes(msg, yesStr)
	self.msgLbl.text = msg
	self.yesLbl.text = yesStr or "确定"
	self.noBtn.gameObject:SetActive(false)
	self.yesBtn.gameObject:SetActive(true)
	self:SetYesPos()
end


--Lua显示Yes按钮回调
function My.ShowYesCb(name)
	local ui = UIMgr.Get(name)
	ui:SetYes(My.msg, My.yesStr)
end


--显示Yes按钮
--msg(string):显示内容
--yesCb(function):注册方法
--obj(table):所在对象
--yesStr(string):按钮内容
--alignment传入如NGUIText.Alignment.Right ：控制字体对齐左对齐居中还是右对齐
function My.ShowYes(msg, yesCb, obj, yesStr, alignment)
	--// LY add bedin
	if My.willCloseWnd == true then
		My.tempShowData = {};
		My.tempShowData.type = 1;
		My.tempShowData.msg = msg;
		My.tempShowData.yesCb = yesCb;
		My.tempShowData.obj = obj;
		My.tempShowData.yesStr = yesStr;
		My.tempShowData.alignment = alignment;
		return;
	end
	--// LY add end

	My.alignment=alignment;
	My.msg = msg
	My.yesStr = yesStr
	if yesCb then My.yesCb:Add(yesCb, obj) end
	UIMgr.Open("MsgBox", My.ShowYesCb)
end

function My:SetYesNo(msg, yesStr, noStr)
	self.msgLbl.text = msg
	self.msgLbl.alignment=My.alignment~=nil and My.alignment or NGUIText.Alignment.Center
	self.noLbl.text = noStr or "取消"
	if self.seconds then
		if not self.timer then
			self.timer = ObjPool.Get(iTimer)
		end
		self.timer.invlCb:Add(self.InvlCb, self)
		self.timer.complete:Add(self.Complete, self)
		self.timer.seconds = self.seconds
		self.yesStr = yesStr or "确定"
		self.yesLbl.text = string.format("%s[00ff00](%s)[-]", self.yesStr, self.seconds)
		self.timer:Start()
	else
		self.yesLbl.text = yesStr or "确定"
	end
	self.noBtn.gameObject:SetActive(true)
	self.yesBtn.gameObject:SetActive(true)
	self:SetYesNoPos()
end

function My:InvlCb()
	if not self.seconds then return end
	self.seconds = self.seconds - 1
	self.yesLbl.text = string.format("%s[00ff00](%s)[-]", self.yesStr, self.seconds)
end

function My:Complete()
	self:ClickYesBtn()
end

--Lua显示Yes/No按钮回调
function My.ShowYesNoCb(name)
	local ui = UIMgr.Get(name)
	ui:SetYesNo(My.msg, My.yesStr, My.noStr)
end

--显示Yes/No按钮
--msg(string):显示内容
--yesCb(function):yes注册方法
--yesObj(table):yes所在对象
--yesStr(string):yes按钮内容
--noCb(function):no注册方法
--noObj(table):no所在对象
--noStr(string):no按钮内容
--alignment传入如NGUIText.Alignment.Right ：控制字体对齐左对齐居中还是右对齐
function My.ShowYesNo(msg, yesCb, yesObj, yesStr, noCb, noObj, noStr, second, alignment,TogMsg,togCb,togObj,togState,isClose)
	--// LY add bedin
	if My.willCloseWnd == true then
		My.tempShowData = {};
		My.tempShowData.type = 2;
		My.tempShowData.msg = msg;
		My.tempShowData.yesCb = yesCb;
		My.tempShowData.yesObj = yesObj;
		My.tempShowData.yesStr = yesStr;
		My.tempShowData.noCb = noCb;
		My.tempShowData.noObj = noObj;
		My.tempShowData.noStr = noStr;
		My.tempShowData.second = second;
		My.tempShowData.alignment = alignment;
		My.tempShowData.TogMsg = TogMsg;
		My.tempShowData.togCb = togCb;
		My.tempShowData.togObj = togObj;
		My.tempShowData.togState = togState;
		return;
	end
	--// LY add end
	My.alignment=alignment;
	My.msg = msg
	My.noStr = noStr
	if noCb then My.noCb:Add(noCb, noObj) end
	My.yesStr = yesStr
	if yesCb then My.yesCb:Add(yesCb, yesObj) end
	My.seconds = second
	My.TogMsg=TogMsg
	My.togState=togState
	My.isClose=isClose
	if togCb then My.togCb:Add(togCb, togObj) end
	local msg = UIMgr.Get("MsgBox")
	if msg then
		My.ShowYesNoCb("MsgBox")
		msg:Open()
	else
		UIMgr.Open("MsgBox", My.ShowYesNoCb)
	end
end

return My
