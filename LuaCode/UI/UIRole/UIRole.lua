UIRole = UIBase:New{Name = "UIRole"}

local My = UIRole;
--开启索引（1角色面板，2技能面板,3天赋,4背包）
My.OpenIndex = nil;
--当前打开
My.curOpen=0;
My.tb=0
require("UI/UIRole/UIRoleAttr")
require("UI/UIRole/UIRoleSkill")
require("UI/UIRole/UIInnate")
require("UI/UIBackpack/UIBag")
require("UI/UIBackpack/WearsShow")
require("UI/UIRole/Elixir/UIElixir")
local Attr = UIRoleAttr;
local Skill = UIRoleSkill;
local Innt = UIInnate;
local Bag = UIBag
My.Icons={};
My.roleOpen=false

function My:SelectOpen( index,tb )
	if index~=nil then

		if index == 5 then
			if OpenMgr:IsOpen(707) == false then
				local des = (tostring(SystemOpenTemp["707"].trigParam)).."级开启，角色等级尚未达到";
				UITip.Log(des);
				return ;
			end
		end
	
		My.OpenIndex = index;
		My.tb=tb
	else
		return;
	end

	local ui = UIMgr.Get(self.Name)
	if ui then
		ui:Open()
		ui:OpenChoose()
	else
		UIMgr.Open(UIRole.Name)
	end
end
function My:OpenTabByIdxBeforOpen(index, tb)
	My.OpenIndex = index;
	My.tb=tb
 end
 function My:OpenTabByIdx(t1, t2, t3, t4)
 
 end
function My:InitCustom()
	local name = self.Name
	local root = self.root
	local TF = TransTool.Find
	local TFC = TransTool.FindChild
	local UC = UITool.SetLsnrClick
	local CG = ComTool.Get

	self.wearShow = ObjPool.Get(WearsShow)
	self.wearShow:Init(TF(self.root, "WearsShow"))
	self.AttrBtnTog = CG(UIToggle,root,"Btn/AttrBtn",name,false)
	self.CollectionBtnTog = CG(UIToggle,root,"Btn/CollectionBtn",name,false)
	self.SkillBtnTog = CG(UIToggle,root,"Btn/SkillBtn",name,false)
	self.InnateBtnTog =CG(UIToggle,root,"Btn/InnateBtn",name,false)
	self.BagTog=CG(UIToggle,root,"Btn/BagBtn",name,false)
	self.ElixirTog=CG(UIToggle,root,"Btn/ElixirBtn",name,false)
	self.AttrBtnRed=TFC(root,"Btn/AttrBtn/Red",name)
	self.CollectionBtnRed=TFC(root,"Btn/CollectionBtn/Red",name)
	self.SkillBtnRed=TFC(root,"Btn/SkillBtn/Red",name)
	self.InnateBtnRed=TFC(root,"Btn/InnateBtn/Red",name)
	self.ElixirBtnRed=TFC(root,"Btn/ElixirBtn/Red",name)
	self.BagBtnRed=TFC(root,"Btn/BagBtn/Red",name)
	self.iRoot = TF(root,"RoleInnate",name)
	self.iRoot.gameObject:SetActive(false);
	self.aRoot = TF(root, "RoleAttr", name)
	self.sRoot = TF(root, "RoleSkill", name)
	self.bRoot = TFC(root, "PropInfoView")
	self.eRoot = TF(root, "ElixirMenu", name)
	

	--转身等级
	if not InnateMgr.IsOpen()  then
		self.InnateBtnTog.enabled=false
	else 
		--Innt:Init(self.iRoot);
	end

	UC(root, "Btn/AttrBtn", name, self.AttrC, self)
	UC(root, "Btn/CollectionBtn", name, self.CollectionC, self)
	UC(root, "Btn/SkillBtn", name, self.SkillC, self)
	UC(root, "Btn/InnateBtn", name, self.InnateC, self)
	UC(root, "Btn/BagBtn", name, self.OnBag, self)
	UC(root, "Btn/ElixirBtn", name, self.OnElixir, self)
	UC(root, "close", name, self.CloseC, self)

	if not self.tgDic then self.tgDic={} end
	self.tgDic["1"]=Attr
	self.tgDic["2"]=Skill
	self.tgDic["3"]=Innt
	self.tgDic["4"]=Bag
	self.tgDic["5"]=UIElixir

	self:OpenChoose()

	self:SetPersist()
end


function My:Lsnr(fn)
	InnateMgr.eRed[fn](InnateMgr.eRed, self.SetInnateRed, self)
	SkillMgr.eSkillUpdate[fn](SkillMgr.eSkillUpdate,self.SetSkillRed,self)
	ElixirMgr.eAction[fn](ElixirMgr.eAction, self.SetElixirRed, self)
	EquipCollectionMgr.eRed[fn](EquipCollectionMgr.eRed,self.SetCollRed,self)
end

function My:SetAttrRed( )
	if SuccessMgr.isAction or FashionMgr.BigRed then
		self.AttrBtnRed:SetActive(true)
	else
		self.AttrBtnRed:SetActive(false)
	end
end
function My:SetInnateRed()
	self.InnateBtnRed:SetActive(InnateMgr.red)
end
function My:SetSkillRed()
	self.SkillBtnRed:SetActive(SkillMgr.Allred)
end

function My:SetElixirRed()
	self.ElixirBtnRed:SetActive(ElixirMgr.isShow)
end

function My:SetCollRed()
	self.CollectionBtnRed:SetActive(EquipCollectionMgr.collRed)
end

function My:OpenChoose()
		if My.OpenIndex==nil or My.OpenIndex == 1 then
			self.AttrBtnTog.value = true;
			self:SBActive(1);
		elseif My.OpenIndex == 2 then
			self.SkillBtnTog.value = true;
			self:SBActive(2);
		elseif My.OpenIndex == 3 and InnateMgr.IsOpen() then
			self.InnateBtnTog.value = true;
			self:SBActive(3);
		elseif My.OpenIndex == 4 then
			self.BagTog.value = true;
			self:SBActive(4);
		elseif My.OpenIndex == 5 then
			self.ElixirTog.value = true;
			self:SBActive(5);
		elseif My.OpenIndex==6 then
			self.CollectionBtnTog.value=true
			self:CollectionC()
		else
			self.AttrBtnTog.value = true;
			self:SBActive(1);
		end
end

function My:AttrC(go)
	self:SBActive(1)
end

function My:CollectionC(go)
	self:SBActive(6)
end

function My:SkillC(go)
	self:SBActive(2)
end
function My:InnateC(go)
	self:SBActive(3)
end

function My:OnBag(go)
	self:SBActive(4)
end

function My:OnElixir(go)
	self:SBActive(5)
end

function My:SBActive(index)
	if My.curOpen==index then
		return
	end
	if InnateMgr.IsOpen() then
		Innt:Close();
	elseif index ==3  then
		UITip.Log("功能未开启");
		return;
	end
	if My.curOpen then
		if My.curOpen==6 then
			UIMgr.Close(UIEquipCollection.Name)
		else
			local after = self.tgDic[tostring(My.curOpen)]
			if after then after:Close() end
		end
	end
	My.curOpen=index;
	if index == 1 then
		if not Attr.root then Attr:Init(self.aRoot) end
		Attr:Open();
	elseif index == 2 then
		if not Skill.root then Skill:Init(self.sRoot)end
		Skill:Open();
	elseif index ==3 then 
		if not Innt.root then Innt:Init(self.iRoot)end
		Innt:Open();
	elseif index ==4 then 
		if not Bag.go then Bag:Init(self.bRoot) end
		Bag:Open();
	elseif index == 5 then 
		if not UIElixir.go then 
			UIElixir:Init(self.eRoot) end
		
		UIElixir:Open();
	elseif index==6 then
		UIEquipCollection:OpenUI()
	else
		--print(index);
		error("index is not right");
	end
	local showState = (index==1 or index==4) and true or false
	self.wearShow:ActiveState(showState)
	GetWayFunc.SetJump(self.Name,index)
end


function My:SetTitle(tName)
	UITop:SetTitle(tName);
end


function My:CloseC()
	local ui = UIMgr.Get(UIEquipCollection.Name)
	if ui then
		ui:Close()
	end
	self:Close()
	JumpMgr.eOpenJump()
end


--因为设置了持久化，所以打开的时候需要重新设置下Texture
function My:OpenCustom()
	if Bag.go then Bag.panel:UpdateViewTexture() end
	if self.isReconnect==true then
		self.isReconnect=nil
		if self.wearShow then 
			self.wearShow:CleanData() 
			self.wearShow:InitData()
		end
	elseif 
		self.wearShow then self.wearShow:UpdateTexture()
	end
	local index = My.curOpen
	My.curOpen=nil
	self:Lsnr("Add")
	My.roleOpen=true
		--红点
	self:SetAttrRed();
	self:SetInnateRed();
	self:SetSkillRed()
	self:SetElixirRed()
	self:SetCollRed()
	self:OpenChoose(index)


	self.ElixirTog.gameObject:SetActive(OpenMgr:IsOpen(707))
	self.CollectionBtnTog.gameObject:SetActive(UIEquipCollection:IsOpen())
end

function My:CloseCustom(  )
	if LuaTool.IsNull(self.root)  then
		return
	end
	self.wearShow:CleanMd();
	My.roleOpen=false
	Attr:Close();
	Skill:Close();
	Innt:Close();
	Bag:Close()
	UIElixir:Close();
	Attr:Dispose();
	Skill:Dispose();
	Innt:Dispose();
	UIElixir:Dispose()
	My.OpenIndex = nil;
	self:Lsnr("Remove");
end

function My:Clear( isReconnect )
	self:Close()
	if isReconnect then
		if self.wearShow then self.isReconnect=true end
        return
    end
	if LuaTool.IsNull(self.root)  then
		return
	end
	self.isReconnect=nil
	My.roleOpen=false
	self:Lsnr("Remove");
	Attr:Close();
	Skill:Close();
	Innt:Close()
	Bag:Close()
	UIElixir:Close()
	Attr:Clear();
	Skill:Clear();
	Innt:Clear();
	UIElixir:Clear()
	Bag:Dispose()
	if self.wearShow then ObjPool.Add(self.wearShow) self.wearShow=nil end
	My.curOpen=nil;
	My.OpenIndex = nil;
	My.tb=0
	local ulds = UIRole.Icons;
	for i=#ulds,1,-1 do
		AssetMgr:Unload(ulds[i],false);
		UIRole.Icons[i]=nil;
	end
	SkillHelp.Clear()
	self.active = 0
	Destroy(self.gbj)
	AssetMgr:Unload(self.Name..".prefab")
	UIMgr.Dic[self.Name]=nil
end

---/// LY add begin

function My:Update()
	if Bag ~= nil then
		Bag:Update();
	end
end


function My:DisposeCustom()
	
end

---/// LY add end

return My
