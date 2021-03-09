SkillCell =Super:New{Name="SkillCell"}

My = SkillCell;

local SB = SkillBaseTemp;
local SL = SkillLvTemp;
local AssetMgr=Loong.Game.AssetMgr;
local GO = UnityEngine.GameObject;

--初始化
function My:Init(root,bool,sv)
	self.isOther=bool
	self.sv = sv
	self.root = root;
	local rt = root.transform;
	local TF = TransTool.Find;
	local TFC = TransTool.FindChild;
	local CG = ComTool.Get;
	local name = rt.name;
	self.SName = CG(UILabel,rt,"SkillName",name,false);
	self.SIcon = CG(UITexture,rt,"SkillIcon",name,false);	
	self.SIconMask =  TFC(rt,"IconMask",name);
	self.bgBtn= TF(rt,"bgBtn",name)
	self.bgBtn=self.bgBtn.gameObject
	if bool==true then
		self.choose=CG(UIToggle,rt,"choose",name);
		self.up=TF(rt,"up",name);
	else
		self.eff=TFC(rt,"eff")
		self.eff:SetActive(false)
		self.red=TFC(rt,"red")
		self.skilllv=CG(UILabel,rt,"Skilllv",name)
		self.skilllv.text="Lv.1"
		self.red:SetActive(false)
		self.SelectO = TF(rt,"Select",name);		
		self.SelectLabel = CG(UILabel,rt,"Select/SkillNameS",name,false);
		self.SUnLock = CG(UILabel,rt,"SkillUnLock",name,false);
		self.isOpen = false;
		-- UITool.SetAllGray(self.bgBtn);
		-- UITool.SetGray(self.SIcon);
	end
	local US = UITool.SetLsnrSelf;
	US(root, self.SelectSkill, self, nil, false);
end

--被选中
function My:SelectSkill(  )
	self.sv:LightUpCell(self);
end
function My:ShowEff(  )
	self.eff:SetActive(false)
	self.eff:SetActive(true)
end
--点击发送
function My:OnChange()
	EventMgr.Trigger("SetSkState",self.skillId)
end
--点击换位置
function My:OnUp(  )
	UISetSkill:doSort(self.root.name,self );
end
--设置go 的name
function My:SetName( num )
	self.root.name=num
end
--设置数据
function My:SetData(skillId,bool,value)
	self.skillId = skillId;
	local sId = tostring(skillId);
	local baseid = SL[sId].baseid;
	self.tb=SL[sId].tb;
	self.baseid = baseid;
	-- self.fistid = SL[sId].fistid
	if SL[sId] ~= nil then
		self.SName.text = SL[sId].name;
		if bool==true then
			local b = true
			if value ~= nil then
				b=value
			end
			self.choose.value=b
			--监听
			local  UC = UITool.SetLsnrSelf;
			self.root.name=baseid
			UC(self.choose,self.OnChange,self, nil, false);
			UC(self.up,self.OnUp,self, nil, false);
		else
			baseid = tostring(baseid);
			local sbInfo = SB[baseid];
			if sbInfo==nil then
				iTrace.Error("soon" ," 技能配置表没有对应，基础配置表缺少id为"..baseid.."  的技能配置");
				return;
			end
			self.SUnLock.text = sbInfo.unlockDes;
			self.SelectLabel.text = SL[sId].name;
			self.root.name=sbInfo.sort
			self.sort=sbInfo.sort
		end
		self.iconText=SL[sId].icon
		AssetMgr.Instance:Load(self.iconText,ObjHandler(self.LoadCB, self));
	end
end
--设置新版本信息
function My:SetInfo( skillInfo )
	-- local lv = "Lv.max"
	-- if skillInfo.undermax then
	lv = "Lv("..skillInfo.level.."/"..skillInfo.limLv..")"
	-- end
	self.skilllv.text=lv
	self.red:SetActive(skillInfo.red) 
	self.skillInfo=skillInfo;
	self:OpenSkill()
end

--加载技能图片完成回调
function My:LoadCB(obj)
	if self.SIcon == nil then
		AssetTool.UnloadTex(obj.name)
		return;
	end
	self.SIcon.mainTexture = obj;
end

--设置格子选择状态
function My:Select(active)
	if self.SelectO == nil then
		return;
	end
	local haveEpi = false
	if active==true then 
		local EpgId = self.skillInfo ~=nil and  self.skillInfo .seal_id or nil
		SkillDescribe:SetInfo(self.skillInfo,EpgId);
		UIRoleSkill:activeEpigraph(self)
		UIRoleSkill:SetUpRed(self.skillInfo)
		UIRoleSkill:SetUpGray(self.skillInfo)
	end
	self.SelectO.gameObject:SetActive(active);
	self.SName.gameObject:SetActive(not active);
	if active==false then
		self.eff:SetActive(false)
	end
end

function My:OpenSkill()
	if self.SIconMask == nil then
		return;
	end
	self.isOpen=self.skillInfo.isOpen
	if self.isOpen then
		self.SIconMask:SetActive(false);
		UITool.SetAllNormal(self.bgBtn);
		UITool.SetNormal(self.SIcon);
		self.SUnLock.color=Color.New(244,221,189,255)/255
	else
		self.SIconMask:SetActive(true);
	    UITool.SetAllGray(self.bgBtn);
		UITool.SetGray(self.SIcon);
		self.SUnLock.color=Color.New(242,25,25,255)/255
	end
end

function My:Dispose()
	-- self.root.transform.parent = nil;
	AssetMgr.Instance:Unload(self.iconText,false);
	if self.isOther then
		GameObject.DestroyImmediate(self.root);

	else
		soonTool.Add(self.root,"SkillCell")
	end
end


