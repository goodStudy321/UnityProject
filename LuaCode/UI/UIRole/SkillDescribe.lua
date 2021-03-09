SkillDescribe = {}

My = SkillDescribe;

local SB = SkillBaseTemp;
local SL = SkillLvTemp;
local SO = SystemOpenTemp;
local SE  = tSkillEpg
local AssetMgr=Loong.Game.AssetMgr;

function My:New(o)
 	o = o or {}
 	setmetatable(o,self);
 	self.__index = self;
 	return o;
end
My.rwdLst = {}
--初始化
function My:Init(root)
	self.skillId=0;
	local rt = root;
	local F = TransTool.Find;
	local TFC = TransTool.FindChild;
	local CG = ComTool.Get;
	local UC = UITool.SetLsnrClick;
	local name = rt.name;
	self.SName = CG(UILabel,rt,"SkillName",name,false);
	self.Skilllv = CG(UILabel,rt,"Skilllv",name,false);
	self.SkillAttr = CG(UILabel,rt,"SkillAttr",name,false);
	self.SCD = CG(UILabel,rt,"SkillCD",name,false);
	self.SDesc = CG(UILabel,rt, "SkillDesc",name,false);
	self.SkillNum = CG(UILabel,rt, "SkillNum",name,false);
	self.SkillDis = CG(UILabel,rt, "SkillDis",name,false);
	self.SkillSeal = CG(UILabel,rt, "SkillSeal",name,false);
	self.grid=CG(UIGrid,rt,"Grid",name,false)
	self.upNone=TFC(rt,"upNone",name)
	self.costId=0;
	self.SIcon = CG(UITexture,rt,"SkillIcon",name,false);
end

--设置数据
function My:SetInfo(skillInfo,epgid)
	self:Clear();
	local skillId = skillInfo.skill_id
	self.skillId=tostring(skillId);
	local sId = self.skillId;
	local slInfo = SL[sId]
	soonTool.desCell(My.rwdLst )
	if slInfo ~= nil then
		self.baseid = slInfo.baseid;
		self.SName.text =slInfo.name;
		local cd = slInfo.skillCd / 1000;
		self.SCD.text = tostring(cd) .. "秒";
		AssetMgr.Instance:Load(slInfo.icon,ObjHandler(self.LoadCB, self));
		table.insert( UIRole.Icons, slInfo.icon )
		local dec =slInfo.desc;
		self.SDesc.text = dec
		self.Skilllv.text= "Lv("..skillInfo.level.."/"..skillInfo.limLv..")"
		self.SkillAttr.text=slInfo.hurtDec
		local far = slInfo.farDec
		if far==nil or far=="" then
			far="无"
		end
		self.SkillDis.text=far
		self.SkillNum.text=slInfo.numDec
		--铭文显示 
		local SealDec = "未开启"
		local showEpi = slInfo.SealLim
		if skillInfo.tb==3 or showEpi==nil then
			SealDec="无铭文"
		else
		    if epgid~=nil and SE[tostring(epgid)]~=nil then
				SealDec =  SE[tostring(epgid)].dec
	    	end
		end
		self.SkillSeal.text =SealDec
		--升级条件
		if skillInfo.cost==nil then
			self.upNone:SetActive(true)
		else
			self.upNone:SetActive(false)
			soonTool.AddCell(self.grid,My.rwdLst,skillInfo.itemId,skillInfo.itemNum,0.8)
		end
	else
		iTrace.eError("缺少配置请检查技能id  "..sId);
	end
end


--加载技能图片完成回调
function My:LoadCB(obj)
	if self.SIcon == nil then
		AssetTool.UnloadTex(obj.name)
		return;
	end
	self.SIcon.mainTexture = obj;
end

function My:Clear( )
	self.costId=0;
	soonTool.desCell(My.rwdLst )
	-- if SL[self.skillId] ~= nil  then
	-- 	AssetMgr.Instance:Unload(SL[self.skillId].icon,false);
	-- end
end