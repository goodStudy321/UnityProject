UIRoleSkill = {Name="UIRoleSkill"}

require("UI/UIRole/SkillCell")
require("UI/UIRole/SkillView")
require("UI/UIRole/SkillDescribe")
require("UI/UIRole/Epigraph")
--主动技能列表
ASL = {}
--转生技能列表
RSL = {}
--注册的事件回调函数
local My = UIRoleSkill;
local SB = SkillBaseTemp;
local SL = SkillLvTemp;
local AssetMgr = Loong.Game.AssetMgr
local SSKL = require("UI/UIRole/UISetSkill")
local curSkill = nil
-- My.skillGetWay = {
-- 	"拍卖行",
-- 	"世界Boss",
-- 	"洞天福地",
-- 	"渡劫",
-- 	"魔域Boss"
-- }
function My:Init(go)
	if go == nil then return end
	local name = go.name;
	self.root = go;
	self.name = name;
	local rt = go;
	local TF = TransTool.Find;
	local TFC = TransTool.FindChild;
	local UC = UITool.SetLsnrClick;
	local CG = ComTool.Get;
	
	local red1 = TFC(rt, "TitleBtn/ActiveBtn/red", name);
	local red2 = TFC(rt, "TitleBtn/PassiveBtn/red", name);
	local red3 = TFC(rt, "TitleBtn/ExclusiveBtn/red", name);
	self.redLst={red1,red2,red3}
	
	--铭文初始化
	local epigraph = TF(self.root, "epigraph", self.name);
	self.epigraph=epigraph
	Epigraph:Init(epigraph);
	
	UC(rt, "TitleBtn/ActiveBtn", name, self.ACTC, self);
	UC(rt, "TitleBtn/PassiveBtn", name, self.PASC, self);
	UC(rt, "TitleBtn/ExclusiveBtn", name, self.EXC, self);
	UC(rt, "Active/SkillSetBtn", name, self.SSB, self);
	self.SkillCellTran = TFC(rt,"SkillCell",name);

	soonTool.setPerfab(self.SkillCellTran,"SkillCell")
	self.ActBtnTog = CG(UIToggle,rt.transform,"TitleBtn/ActiveBtn",name,false);
	self.PassBtnTog = CG(UIToggle,rt.transform,"TitleBtn/PassiveBtn",name,false);
	self.ExclBtnTog = CG(UIToggle,rt.transform,"TitleBtn/ExclusiveBtn",name,false);
	self.bntLst={self.ActBtnTog,self.PassBtnTog,self.ExclBtnTog}
	-- self.TTB = CG(UISprite, rt.transform, "TitleBtn", name, false);
	self:InitSDetail();
	--初始化自动界面
	self.ssRoot = TF(rt,"UISetSkill",self.name)
	self.upRed=TFC(rt,"up/red")
	self.upbtn = TFC(rt,"up",self.name)	
	self.openqpi = TFC(rt,"openqpi",self.name)
	self.openqpiRed = TFC(rt,"openqpi/red",self.name)
	self.openqpiRed:SetActive(false)
	--提示
	UC(rt, "dec", name, self.decClick, self);
	UC(rt, "up", name, self.upClick, self);
	UC(rt, "openqpi", name, self.EpiOpen, self);
	self.Activepanel=TFC(rt,"Active")
	self.Passivepanel=TFC(rt,"Passive")
	self.Exclusivepanel=TFC(rt,"Exclusive")
	self.actScroView= CG(UIScrollView,rt, "Active/ScrollView",name)
	self.pasScroView =  CG(UIScrollView,rt,"Passive/ScrollView",name)
	self.ExcScroView =  CG(UIScrollView,rt,"Exclusive/ScrollView",name)
end

function My:decClick( )
    local dec=InvestDesCfg["1904"].des;
    UIComTips:Show(dec, Vector3(60,-249,0),nil,nil,nil,400,UIWidget.Pivot.BottomLeft);
end

function My:EpiOpen( )
	if curSkill~=nil and self.skillInfo~=nil and self.skillInfo.isOpen then
		local p_skill =self.skillInfo
		if  p_skill.seal_Open==false then
			UITip.Log(p_skill.Seallim.."级开启")
			return
		end
		Epigraph:Open()
	end
end
	
function My:SetUpRed(skillInfo )
	self.isOpen=skillInfo.isOpen
	self.upRed:SetActive(skillInfo.upred);
end

function My:SetUpGray( )
	local skillinfo=self.skillInfo
	local limlv = skillinfo.limLv
	if limlv==nil or limlv==0 then
		self.upbtn:SetActive(false)
		return
	end
	local type =math.floor( skillinfo.skill_id*0.000001)
	if type==13 then
		self.upbtn:SetActive(false)
		return
	end
	self.upbtn:SetActive(true)
	if	skillinfo.itemId~=nil then
		UITool.SetNormal(self.upbtn)
	else
		self.upRed:SetActive(false);
        UITool.SetGray(self.upbtn);
	end
end

function My:upClick( )
    if  self.skillInfo.upred then
		SkillMgr:SkillUp(self.skillInfo.next_skilid)
	elseif self.isOpen==false then
		if self.skillInfo.cost==nil then
			UITip.Log("需要先解锁技能")
		else
			self:AddPoint(  )
		end
    elseif self.skillInfo.undermax==false then
        UITip.Log("技能已升满")
    else
        self:AddPoint(  )
    end
end
function My:AddPoint(  )
	local type_id = self.skillInfo.itemId
	if type_id==nil then
		return
	end
    local item = UIMisc.FindCreate(type_id)
	local getway = item.getwayList
	if getway==nil or #getway==0 then
		return
	end
	local pos = Vector3(460,-101,0)
	GetWayFunc.SetJump(UIRole.Name,2)
    GetWayFunc.GetWayIdList(getway,pos,type_id)
	-- UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb ,self)
end

--[[  
function My:OpenGetWayCb(name)
    local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(460,-101,0))
	local len = #My.skillGetWay
	for i = 1,len do
		ui:CreateCell(My.skillGetWay[i], self.OnClickGetWayItem, self)
	end
end

function My:OnClickGetWayItem(name)
	if name == "拍卖行" then
		UIAuction:OpenTabByIdxBeforOpen(1,5)
        UIMgr.Open(UIAuction.Name)
        JumpMgr:InitJump(UIRole.Name,2)
	elseif name == "世界Boss" then
        BossHelp.OpenBoss(1)
        JumpMgr:InitJump(UIRole.Name,2)
    elseif name == "洞天福地" then
        BossHelp.OpenBoss(2)
        JumpMgr:InitJump(UIRole.Name,2)
    elseif name == "渡劫" then
        UIRobbery:OpenRobbery(1)
        JumpMgr:InitJump(UIRole.Name,2)
    elseif name == "魔域Boss" then    
        UIMgr.Open(UIDemonArea.Name)
        JumpMgr:InitJump(UIRole.Name,2) 
	end
end
--]]  
function My:lsnr( fun )
	SkillMgr.eSkillUpdate[fun](SkillMgr.eSkillUpdate,self.reRad,self)
	SkillMgr.choseSuc[fun](SkillMgr.choseSuc,self.choseSucShow,self)
	SkillMgr.lvUp[fun](SkillMgr.lvUp,self.LvUpShow,self)
end

function My:LvUpShow( )
	local cell = SkillView.CurCell
	cell:ShowEff()
end
function My:choseSucShow( )
	Epigraph:ShowEff()
end

function My:activeEpigraph( skillcell )
	curSkill=skillcell;
	local skill_id =curSkill.skillId
	local slInfo =  SL[tostring(skill_id)]
	self.skillInfo=skillcell.skillInfo
	local showEpi = slInfo.SealLim
	if skillcell.tb==3 or showEpi==nil  then
		self.openqpi:SetActive(false)
		return
	end
	local p_skill = self.skillInfo
	self.openqpi:SetActive(true)
	if p_skill.isOpen==false  then
		-- self.openqpi:SetActive(false)
		UITool.SetGray(self.openqpi)
	else
		UITool.SetNormal(self.openqpi)
		if  p_skill.chosered or  p_skill.seal_up then
			self.openqpiRed:SetActive(true)
		else
			self.openqpiRed:SetActive(false)
		end
		Epigraph:show(curSkill.skillInfo,curSkill.skillId)
	end
end

function My:reRad(  )
	for i=1,#self.redLst do
		self.redLst[i]:SetActive(SkillMgr.redLst[i])
	end
end

function My:InitSDetail()
	local TF = TransTool.Find;
	local SDesc = TF(self.root, "SkillDescri", self.name);
	self.SDetail = SkillDescribe;
	self.SDetail:Init(SDesc);
end

--初始化
function My:InitSkillSv(sv,type)
	SkillView:Close();
	SkillView:Open(sv,self.SDetail,type);
	SkillView:ChooseSkill();
	sv:ResetPosition()
	soonTool.ChooseInScrollview( curSkill.root,sv)
end

--打开面板
function My:Open()
	self:reRad(  )
	self:lsnr("Add")
	self.root.gameObject:SetActive(true);
	Epigraph:SetFalseSelf()
	local tb = SkillHelp.tb
	if tb==0 or tb==1 then
		self.Activepanel:SetActive(true)
		self.bntLst[1].value = true;
		self:ACTC();
	elseif tb==2 then
		self.Passivepanel:SetActive(true)
		self.bntLst[2].value = true;
		self:PASC()
	elseif tb==3 then
		self.Exclusivepanel:SetActive(true)
		self.bntLst[3].value = true;
		self:EXC()
	end
	SkillHelp.tb=0
end

--关闭面板
function My:Close()
	if LuaTool.IsNull(self.root)  then
		return
	end
	self.root.gameObject:SetActive(false);
end

--刷新面板
function My:Refresh()
	
end

--点击主动按钮
function My:ACTC()
	self:InitSkillSv(self.actScroView,1)
end

--点击被动按钮
function My:PASC()
	self:InitSkillSv(self.pasScroView,2)
end


--点击专属按钮
function My:EXC()
	self:InitSkillSv(self.ExcScroView,3)
end
--点击技能设置按钮
function My:SSB()
	SSKL:Init(self.ssRoot,1)
	SSKL:Open()
end 

-- --点击变身按钮
-- function My:DFC(go)

-- end

--开启天赋技能按钮
function My:OpenTalent()
	-- self.TB.gameObject:SetActive(true);
	-- self.TTB.width = self.TTB.width + 119;
end

--开启变身技能按钮
function My:OpenDeform()
	-- self.DB.gameObject:SetActive(true);
	-- self.TTB.width = self.TTB.width + 119;
end



function My:Dispose()
	curSkill=nil
	self:lsnr("Remove" )
	if self.root==nil or self.SDetail==nil then
		return
	end
	self.CurCell = nil;
	self.SDetail:Clear( );
	SkillView:Close();
	UISetSkill:ClearSkillCells();
end

function My:Clear(  )
	self:Dispose()
	soonTool.DesGo("SkillCell")
	TableTool.ClearUserData(self)
end