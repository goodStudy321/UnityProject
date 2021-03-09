require("UI/UIRole/SkillCell")
require("UI/UIRole/SkillDescribe")

SkillView = {Name = "SkillView"}
local My = SkillView;
local GO = UnityEngine.GameObject;
local SL = SkillLvTemp;
--技能格子列表
My.SkillCells = {}
My.CurCell=nil
--
My.tb=tb;
My.tbLst={}

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end
-- --单纯的打开
-- function My:onlyOpen( )
-- 	self.root.gameObject:SetActive(true)
-- 	if self.SDetail==nil then
-- 		return;
-- 	end
-- 	self:ChooseSkill()
-- 	-- self.SDetail:SetData(My.CurCell.skillId);
-- end
--单纯的关闭
function My:onlyClose( )
	self.root.gameObject:SetActive(false)
end

--trans==>ScrollView对象，SDetail==>技能描述类对象，skType==>技能类型
function My:Open(trans,SDetail,skType)
	local trans= trans.transform
    self.root = trans;
    self.SDetail = SDetail;
    local name = trans.name;
    local TF = TransTool.Find;
	local UC = UITool.SetLsnrClick;
    local CG = ComTool.Get;
    self.UITable = CG(UIGrid,trans,"Table",name,false);
	self:InitSkillCell(skType);
	self:lsnr("Add")
end

function My:lsnr( fun )
	SkillMgr.eSkillUpdate[fun](SkillMgr.eSkillUpdate,self.reSkill,self)
end

function My:InitSkillCell(skType)
	local skilllst = SkillMgr.SkillLst
	for k,v in pairs(skilllst) do
		local tb = v.tb
		if skType == tb then
			local scGo =soonTool.Get("SkillCell",self.UITable)
			local skillCell = SkillCell:New();
			skillCell:Init(scGo,nil,self);
			skillCell:SetData(v.skill_id);
			skillCell:SetInfo(v);
			table.insert( My.SkillCells, skillCell)
		end
	end
	self.UITable:Reposition();
	table.sort(My.SkillCells, self.doSort);
end
function My.doSort(a,b)
	return a.sort<b.sort
  end
--选择默认格子
function My:ChooseSkill( )
	local index = 1
	if SkillHelp.skillBaseId~=0 then
		local len = # My.SkillCells
		for i=1,len do
			local cell =  My.SkillCells[i]
			if cell.baseid == SkillHelp.skillBaseId then
				SkillHelp.skillBaseId=0
				index=i
				break;
			end
		end
	end
	if  My.SkillCells[index]==nil then
		return
	end
	self:LightUpCell( My.SkillCells[index]);
end
--更新技能
function My:reSkill( )
	self:SetOpenSkill()
	if My.CurCell~=nil then
		My.CurCell:Select(true);
	end
end

--设置开放技能
function My:SetOpenSkill()
	local SKLst = SkillMgr.SkillLst
	for k,v in pairs( My.SkillCells) do
	    for k1,v1 in pairs(SKLst) do
			if v.baseid == v1.baseid then
				v:SetData(v1.skill_id);
				v:SetInfo(v1);
				break;
			end
		end
	end
end
--获取格子
function My:GetCell(go)
	if go == nil then
		return;
	end
	for k, v in pairs(My.SkillCells) do
		if go.name == v.root.name then
			return v;
		end
	end
	return nil;
end

--点亮格子
function My:LightUpCell(cell)
	if cell.skillId == nil then
		return;
	end
	if My.CurCell == nil then
		cell:Select(true);
		My.CurCell = cell;
	else
		if My.CurCell ~= cell then
			My.CurCell:Select(false);
			cell:Select(true);
			My.CurCell = cell;
		end
	end
end

function My:Close()
	if  LuaTool.IsNull(self.root) then
		return
	end
	if My.CurCell ~= nil then
		My.CurCell:Select(false);
		My.CurCell=nil
	end
	self:ClearSkillCells();
	self:lsnr("Remove")
end

--清除技能格子列表
function My:ClearSkillCells()
	soonTool.ObjAddList(My.SkillCells)
end