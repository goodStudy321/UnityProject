WBAtkBossInfo = {Name = "WBAtkBossInfo"}
local My = WBAtkBossInfo;

function My:Init(trans)
    local go = trans.gameObject;
    self.mGo = go;
    local UCS = UITool.SetLsnrSelf;
    UCS(go, self.OnAtkBoss, self);
    self:SetActive(false);
end

--设置Boss的ID
function My:SetBossID(id)
    self.Id = id;
    self:SetActive(true);
end

--激活对象
function My:SetActive(active)
    if self.mGo == nil then
        return;
    end
    self.mGo:SetActive(active);
end

--点击攻击Boss
function My:OnAtkBoss()
    id = self.Id;
    if id == nil then
        return;
    end
    AtkInfoMgr.SetCurTarget(id);
    id = tonumber(id);
    if id == "0"then
        return;
    end
    SelectRoleMgr.instance:StartNavPath(id,1);
end