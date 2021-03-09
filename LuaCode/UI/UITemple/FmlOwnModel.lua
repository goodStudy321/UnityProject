FmlOwnModel={Name="FmlOwnModel"}
local My = FmlOwnModel
local prv = {}

function  My:Init(root,FmlOwner)
    self.modelRoot=root
    self:SetOwnInfo(FmlOwner)
    self:SetModel()
end


--设置道庭盟主信息
function My:SetOwnInfo(FmlOwner)
    self.FmlOwner = {}
    self.FmlOwner.sex = FmlOwner.sex
    self.FmlOwner.category = FmlOwner.category
    self.FmlOwner.level=FmlOwner.level
    self:SetSkinList(FmlOwner.skin)
end

--设置挑战者皮肤信息
function My:SetSkinList(skinLsit)
    if skinLsit == nil then
        return;
    end
    local len = #skinLsit;
    if len == 0 then
        return;
    end
    self.SkinList = {}
    for i = 1, len do
        self.SkinList[i] = skinLsit[i];
    end
end

--设置模型
function My:SetModel()
    self:DestroyM()
    local FO = self.FmlOwner
    local typeId = (FO.category * 10 + FO.sex) * 1000 + FO.level
    local rs = RoleSkin:New()
    rs.eLoadModelCB:Add(self.LoadCB,self);
    rs:Create(self.modelRoot,typeId,self.SkinList,FO.sex)
    self.rsObj = rs
end

--加载模型完成回调
function My:LoadCB(go)
    if go == nil then
        return;
    end
    go.transform.localEulerAngles = Vector3.zero;
end

--销毁模型
function My:DestroyM()
    if self.rsObj == nil then
        return
    end
    self.rsObj:Dispose()
end

function My:Clear()
    self:DestroyM()
    TableTool.ClearUserData(self)
end

return My