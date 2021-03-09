UIRoleAttr = {Name="UIRoleAttr"}

local My = UIRoleAttr

function My:Init(go)
	if go==nil then return end
	self.root = go;
	My:GAO();
	self:SetLsnr("Add")
end

function My:AddLsnr()
	FightVal.eChgFv:Add(self.Refresh,self);
	local EH = EventHandler;
	local EM = EventMgr;
	self.OnChangeExp = EH(self.Refresh, self)
	EM.Add("OnChangeExp",self.OnChangeExp);
	self.OnChangePro = EH(self.Refresh, self);
	EM.Add("OnUpdateProEnd",self.OnChangePro);
	--魅力
	RoleAssets.eCharm:Add(self.reCharm,self);
end

function My:RemoveLsnr()
	FightVal.eChgFv:Remove(self.Refresh,self);
	local EM = EventMgr;
	EM.Remove("OnChangeExp",self.OnChangeExp);
	EM.Remove("OnUpdateProEnd",self.OnChangePro);
	RoleAssets.eCharm:Remove(self.reCharm,self);
end

function My:SetLsnr(key)
	OpenMgr.eOpen[key](OpenMgr.eOpen, self.OpenBtn, self)	
end

function My:GAO()
	local CT = ComTool.Get;
	local UL = UILabel; 
	local TF = TransTool.FindChild
	local US = UITool.SetLsnrSelf
	local UC = UITool.SetLsnrClick;

	self.slider = CT(UISlider,self.root,"Exp/Slider",name);
	self.sliderv = CT(UL,self.root,"Exp/ValueLabel",name);

	self.fvl = CT(UL,self.root,"FightLabel/Value",name);
	self.avl = CT(UL,self.root,"AttackLabel/Value",name);
	self.abl = CT(UL,self.root,"ArmBreakLabel/Value",name);
	self.hl  = CT(UL,self.root,"HitLabel/Value",name);
	self.crl = CT(UL,self.root,"CriticalLabel/Value",name);
	self.ll  = CT(UL,self.root,"LifeLabel/Value",name);
	self.def = CT(UL,self.root,"DefenceLabel/Value",name);
	self.dod = CT(UL,self.root,"DodgeLabel/Value",name);
	self.tl  = CT(UL,self.root,"TenacityLabel/Value",name);
	self.cvl = CT(UL,self.root,"CritiValueLabel/Value",name);
	self.hdl = CT(UL,self.root,"HarmDeepenLabel/Value",name);
	self.col = CT(UL,self.root,"CriOddsLabel/Value",name);
	self.sal = CT(UL,self.root,"SkillHurtAddLabel/Value",name);
	self.ral = CT(UL,self.root,"RoleArmLabel/Value",name);
	self.msl = CT(UL,self.root,"MoveSpeedLabel/Value",name);
	self.crsl = CT(UL,self.root,"CriResistLabel/Value",name);
	self.hdr = CT(UL,self.root,"HarmDeepenReductLabel/Value",name);
	self.dol = CT(UL,self.root,"DodgeOddsLabel/Value",name);
	self.shml = CT(UL,self.root,"SkillHurtMinLabel/Value",name);
	self.charm=CT(UL,self.root,"charm",name);

	local msgBoxRoot = TransTool.Find(self.root,"MsgBox") 
	self.msgGo=msgBoxRoot.gameObject;
	self.msgGo:SetActive(false);
	self.textLv=CT(UL,msgBoxRoot,"msg");
	self.ysBtn = CT(UIButton,msgBoxRoot,"bg/yesBtn")
	US(self.ysBtn, self.YesCb, self)
	local cls = TF(msgBoxRoot, "CloseBtn")
	US(cls, self.YesCb, self)

	self.worldLv = TF(self.root, "worldLv")
	US(self.worldLv, self.Click, self)

	self.btnTitle = TF(self.root, "btnTitle")
	US(self.btnTitle, self.Click, self)

	self.btnFashion = TF(self.root, "ClothBtn")
	US(self.btnFashion, self.Click, self)

	self.btnSucc = TF(self.root, "SuccBtn")
	US(self.btnSucc, self.Click, self)

	self.fashionRedPoint = TF(self.root, "ClothBtn/RedPoint")
	self.fashionRedPoint:SetActive(FashionMgr.BigRed)

	self.succAction = TF(self.root, "SuccBtn/RedPoint")

	-- self.ambitRedPoint = TF(self.root, "btnAmbit/RedPoint")
	-- self.ambitRedPoint:SetActive(SystemMgr:GetSystemIndex(1,2))
end

function My:Open()
	self.root.gameObject:SetActive(true);
	self:Refresh();
	self:AddLsnr();
	self:UpSuccAction()
end

function My:Close()
    if LuaTool.IsNull(self.root) then
        return
    end
	self.root.gameObject:SetActive(false);
	self:RemoveLsnr();
end

function My:Refresh()
	local mp = User.MapData;
	--战斗力
	local fgt = mp.AllFightValue;
	self.fvl.text = tostring(fgt);
	--经验
	local exp = tostring(mp.Exp);
	exp = tonumber(exp);
	local maxExp = tostring(mp.LimitExp);
	maxExp = tonumber(maxExp);
	local exp = math.NumToStr(exp);
	local max = math.NumToStr(maxExp);
	self.sliderv.text = exp .. "/" .. max;
	self.slider.value = mp.ExpRatio;

	local pt = ProType;
	--战斗属性
	--攻击
	self.avl.text = mp:GetBaseProperty(pt.Atk);
	--破甲
	self.abl.text = mp:GetBaseProperty(pt.Arp);
	--命中
	self.hl.text = mp:GetBaseProperty(pt.Hit);
	--暴击
	self.crl.text = mp:GetBaseProperty(pt.Crit);
	--生命
	self.ll.text = mp:GetBaseProperty(pt.HP);
	--防御
	self.def.text = mp:GetBaseProperty(pt.Def);
	--闪避
	self.dod.text = mp:GetBaseProperty(pt.Miss);
	--坚韧
	self.tl.text = mp:GetBaseProperty(pt.Crit_Anti);

	--极品属性 
	--暴击伤害
	self.cvl.text =mp:GetBaseProperty(pt.Crit_Multi)
	--伤害加深
	self.hdl.text = My.GetNumToPer(mp:GetBaseProperty(pt.Hurt_Rate))
	--暴击几率
	self.col.text =  My.GetNumToPer(mp:GetBaseProperty(pt.Cirt_Doubel))
	--技能伤害增加
	self.sal.text =mp:GetBaseProperty(pt.Skill_Add)
	--人物护甲
	self.ral.text =mp:GetBaseProperty(pt.Role_Def)
	--移动速度
	self.msl.text =mp:GetBaseProperty(pt.ATTR_MOVE_SPEED)
	--暴击抵抗
	self.crsl.text =mp:GetBaseProperty(pt.Crit_Multi_anti)
	--伤害减免
	self.hdr.text = My.GetNumToPer(mp:GetBaseProperty(pt.Hurt_Derate))
	--闪避几率
	self.dol.text =mp:GetBaseProperty(pt.Miss_Double)
	--技能伤害减少
	self.shml.text =mp:GetBaseProperty(pt.Skill_Reduce)
	--魅力值
	self:reCharm();
	-- self.btnAmbit:SetActive(mp.Level >= SystemOpenTemp["46"].trigParam)
end

function My.GetNumToPer( strnum )
	local num = tonumber(strnum)*0.01
	local que =  math.ReDec(num, 1)
	return que.."%"
end

--魅力
function My:reCharm( )
	self.charm.text = RoleAssets.Charm;
end

function My:Click(go)
	local name = go.name
	local open = UIMgr.Open
	if name == "btnAmbit" then
		-- open(UIAmbit.Name)
	elseif name == "btnTitle" then	
		open(UITitle.Name)
	elseif name == "ClothBtn" then
		UIFashionPanel:Show(1)
	elseif name == "worldLv" then	
		self:WorldLvShow()
	elseif name == "SuccBtn" then
		open(UISuccess.Name)
	end
end

function My:WorldLvShow( )
	self.lv = User.instance.MapData.Level;
	self.curWorldLvl=FamilyBossInfo.worldLv; 
	local str = "当前未开启世界等级"
	local dec = self.curWorldLvl-self.lv
	if self.lv>=110 then
		str=UserMgr:chageLv(self.curWorldLvl)
		dec = math.min(50,math.max( 0,dec-10))
		dec=dec*6
	else
		dec =0
	end
	local p_sb = ObjPool.Get(StrBuffer)
	p_sb:Apd("玩家等级达到110级时开启世界等级\n低于世界等级10级时，打怪获得的经验享受加成\n当前世界等级：[66C34EFF]")
	:Apd(str):Apd("[-]\n当前经验加成：[66C34EFF]"):Apd(dec):Apd("%[-]")
	local str1 = p_sb:ToStr()
	self.msgGo:SetActive(true);
	self.textLv.text=str1
	ObjPool.Add(p_sb)
end
function My:YesCb()
	self.msgGo:SetActive(false);
end
function My:OpenBtn(id)
	-- if id == 46 then
	-- 	self.btnAmbit:SetActive(true)
	-- end
end

--更新成就红点
function My:UpSuccAction()
	self.btnSucc:SetActive(SuccessInfo.isOpen)
	self.succAction:SetActive(SuccessMgr.isAction)
end

function My:Dispose()
	self:RemoveLsnr();
	self:SetLsnr("Remove")
end

function My:Clear( )
	self:Dispose()
	TableTool.ClearUserData(self)
end