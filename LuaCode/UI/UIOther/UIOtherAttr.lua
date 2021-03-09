UIOtherAttr = Super:New{Name="UIOtherAttr"}

local My = UIOtherAttr

function My:Init(go)
	local CT = ComTool.Get;
	local UL = UILabel; 

	self.GO = go
	local trans = go.transform
	self.root = trans
	local name = self.Name

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
end

function My:Open()
	self.root.gameObject:SetActive(true);
	self:Refresh();
end

function My:Close()
	self.root.gameObject:SetActive(false);
end

function My:UpdateInfo(info)
	--战斗力
	local fgt = info.power;
	self.fvl.text = tostring(fgt);

	local bp = info.basePro;
	local pt = ProType;
	--战斗属性
	--攻击
	self.avl.text = bp[pt.Atk + 1];
	--破甲
	self.abl.text = bp[pt.Arp + 1];
	--命中
	self.hl.text = bp[pt.Hit + 1];
	--暴击
	self.crl.text = bp[pt.Crit + 1];
	--生命
	self.ll.text = bp[pt.HP + 1];
	--防御
	self.def.text = bp[pt.Def + 1];
	--闪避
	self.dod.text = bp[pt.Miss + 1];
	--坚韧
	self.tl.text = bp[pt.Crit_Anti + 1];

	--极品属性
	--暴击伤害
	self.cvl.text = bp[pt.Crit_Multi + 1];
	--伤害加深
	self.hdl.text = bp[pt.Hurt_Rate + 1];
	--暴击几率
	self.col.text = bp[pt.Cirt_Doubel + 1];
	--技能伤害增加
	self.sal.text = bp[pt.Skill_Add + 1];
	--人物护甲
	self.ral.text = bp[pt.Role_Def + 1];
	--移动速度
	self.msl.text = bp[pt.ATTR_MOVE_SPEED + 1];
	--暴击抵抗
	self.crsl.text = bp[pt.Crit_Multi_anti + 1];
	--伤害减免
	self.hdr.text = bp[pt.Hurt_Derate + 1];
	--闪避几率
	self.dol.text = bp[pt.Miss_Double + 1];
	--技能伤害减少
	self.shml.text = bp[pt.Skill_Reduce + 1];
end

function My:Dispose()
	self.root = nil;
	self.slider = nil;
	self.sliderv = nil;

	self.fvl = nil;
	self.avl = nil;
	self.abl = nil;
	self.hl  = nil;
	self.crl = nil;
	self.ll  = nil;
	self.def = nil;
	self.dod = nil;
	self.tl  = nil;
	self.cvl = nil;
	self.hdl = nil;
	self.khl = nil;
	self.ppl = nil;
	self.idl = nil;
	self.msl = nil;
	self.cvr = nil;
	self.hdr = nil;
	self.khr = nil;
	self.ppr = nil;
	self.idr = nil;
end