DroiyanInfo = {Name="DroiyanInfo"}
local My = DroiyanInfo;
local GO = UnityEngine.GameObject;
local AssetMgr = Loong.Game.AssetMgr;

My.MountPoint = {"Bip001 AssPosition","Bip001 Prop1","Bip001 Spine1"}

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o
end

function My:Init(go,challenger)
    local root = go.transform;
    local name = name;
    self.root = root;
    local CG = ComTool.Get;
    local CGS = ComTool.GetSelf;
    local TF = TransTool.FindChild;
    self.RoleRoot = TF(root,"RoleModel",name);
    self.rank = CG(UILabel,root,"RoleRank",name,false);
    self.roleName = CG(UILabel,root,"RoleName",name,false);
    self.fightVal = CG(UILabel,root,"RoleFight",name,false);
    self.Icon = CG(UISprite,root,"HeadIcon",name,false);
    self:SetChallenger(challenger);
end

--设置挑战者
function My:SetChallenger(challenger)
    if challenger == nil then
        return;
    end
    self:SetChlgInfo(challenger);
    self:SetInfo();
    self:SetHeadIcon();
end

--设置挑战者信息
function My:SetChlgInfo(challenger)
    self.Challenger = {};
    self.Challenger.rank = challenger.rank;
    self.Challenger.role_id = challenger.role_id;
    self.Challenger.role_name = challenger.role_name;
    self.Challenger.sex = challenger.sex;
    self.Challenger.category = challenger.category;
    self.Challenger.level = challenger.level;
    self.Challenger.power = challenger.power;
end

--设置信息
function My:SetInfo()
    if self.Challenger == nil then
        return;
    end
    self.rank.text = string.format( "第%s名",self.Challenger.rank);
    self.roleName.text = self.Challenger.role_name;
    local power = math.NumToStrCtr(self.Challenger.power);
    self.fightVal.text = power;
end

function My:SetHeadIcon()
    if self.Challenger.sex == 0 then
        self.Icon.spriteName = "FVP_head01";
    else
        self.Icon.spriteName = "FVP_head02";
    end
end

function My:Clear()
    TableTool.ClearUserData(self);
end