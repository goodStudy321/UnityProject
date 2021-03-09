RoleListInfo = Super:New{Name="RoleListInfo"}
local My = RoleListInfo;
function My:Ctor()
end

--设置信息
function My:SetInfo(id,typeId,level,name,teamId,familyId,sex,hp,maxHp)
    self.id = id;
    self.typeId = typeId;
    self.level = level;
    self.name = name;
    self.sex = sex;
    self.hp = hp;
    self.maxHp = maxHp;
    self:SetTmFml(teamId,familyId);
end

--刷新当前血量
function My:RfHp(hp,maxHp)
    if self.hp ~= hp then
        self.hp = hp;
    end
    if self.maxHp ~= maxHp then
        self.maxHp = maxHp;
    end
end

--设置队友或盟友属性
function My:SetTmFml(teamId,familyId)
    self.teamId = teamId;
    self.familyId = familyId;
    self:RfTmFml();
end

--刷新队友或盟友属性
function My:RfTmFml()
    local id = self.id;
    local teamId = self.teamId;
    local familyId = self.familyId;
    local isTmFml = RoleList.TeamOfFml(id,teamId,familyId);
    self.isTeamOrFml = isTmFml;
end