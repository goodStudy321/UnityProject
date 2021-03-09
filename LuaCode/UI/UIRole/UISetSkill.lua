UISetSkill= Super:New{Name="UISetSkill"}
local  My = UISetSkill
local SL = SkillLvTemp;
local GO = UnityEngine.GameObject;
--技能格子字典
My.SkillCells = {}
--排序列表
local sortLst ={};
--是否又不存在
local isLife = false;

function  My:Init(root,skType)
	sortLst= SkillMgr.doSortLst;
    local TF = TransTool.Find;
    local  UC = UITool.SetLsnrClick;
    UC(root,"close",self.Name,self.Close,self);
    self.go=root.gameObject;
    self.UITable= ComTool.Get(UITable,root,"Scroll View/Table",self.Name);    
    self.TbRot= self.UITable.transform
	self.toSLDic=SkillMgr.SkillSateList
    self.SkillCellTran = TF(self.TbRot,"SkillCell");
    self.SkillCellTran.gameObject:SetActive(false);
    self:InitSkillCell(skType);
	self.go:SetActive(false); 
	
end

function My:InitSkillCell(skType)
	local UnLock =self:CanUse()	
    for skId,v in pairs(UnLock) do
	  if skType == SL[skId].type then
		local scGo = self:CloneSKC(SL[skId].baseid);
		local skillCell = SkillCell:New();
		skillCell:Init(scGo,true);
		skillCell:SetData(skId,true,self.toSLDic[skId]);
		My.SkillCells[skId]=skillCell
		self:StartDoSort(skillCell )
	  end
	end
	if isLife then
		self:ddddd()
	end
	self.UITable:Reposition();
end
--得到可用技能集合
function My:CanUse( )
	local SKLst = User.instance.MapData.SkillInfoList;
	local len = SKLst.Count - 1;
	local retList = {}
	for i = 0, len do
		local key = SKLst[i].skill_id
		key = tostring(key)
		retList[key]=true
	end
	return retList;
end
--克隆技能格子
function My:CloneSKC(baseId)
    local go = self.SkillCellTran.gameObject;
    local item = GO.Instantiate(go);
    item:SetActive(true);
    item = item.transform;
    item.parent = go.transform.parent;
    item.localPosition = Vector3.zero;
	item.localScale = Vector3.one;
	return item.gameObject;
end


function My:Open(  )
	self.go:SetActive(true);
	self.UITable:Reposition();
end

function My:Close(  )
    local sklist = self.SkillCells
    local len =#sklist
    for k,v in pairs(sklist) do
        self.toSLDic[v.skillId]=v.choose.value
	end
	local Name = tostring(User.instance.MapData.UID).."Skill";
	SettingSL:OnSave(self.toSLDic,Name);
	local Name2 = tostring(User.instance.MapData.UID).."SkillSort";
	SettingSL:OnSave(SkillMgr.doSortLst,Name2);
	SkillMgr.ToSendSort(SkillMgr.doSortLst);
	UITip.Log("技能设置成功")
	--关闭
	self.go:SetActive(false); 
	self:ClearSkillCells();
end

--清除技能格子列表
function My:ClearSkillCells()
	soonTool.ObjAddList(My.SkillCells)
end

function My:StartDoSort(skillCell )
	local x = 0;
	for i=1, #sortLst do
		if skillCell.skillId==sortLst[i] then
			x=i;
			break;
		end
	end
	if x==0 then
		table.insert( sortLst,1,tostring(skillCell.skillId));
		isLife=true;
	else
		skillCell:SetName(x+10);
	end
end

function My:doSort(id)
	id=tonumber(id)-10;
	local t = 0;
	if id==1 then
		t=table.remove( sortLst,1 );
		table.insert( sortLst, t );
		for i=1,#sortLst do
			My.SkillCells[sortLst[i]]:SetName(i+10);
		end
	else
		t=sortLst[id];
		sortLst[id]=sortLst[id-1];
		sortLst[id-1]=t;
		local skill1 = sortLst[id-1]
		local skill2 = sortLst[id]
		-- if skill1==nil or skill2==nil then
		-- 	iTrace.Error("soon","skill1="..skill1.." skill2="..skill2.."id="..id.."lenth="..#sortLst )
		-- 	return;
		-- end
		My.SkillCells[skill2]:SetName(id+10);
		My.SkillCells[skill1]:SetName(id-1+10);
	end
	self.UITable:Reposition();
end
--一次性排序
function My:ddddd( )
	-- iTrace.eLog("我被执行了说明又技能没有被记录到")
	for i=1,#sortLst do
		My.SkillCells[sortLst[i]]:SetName(i+10);
	end
	isLife=false;
end

return My


