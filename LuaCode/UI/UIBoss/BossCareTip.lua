
require("UI/UIBoss/BossCareItem");

BossCareTip= UIBase:New{Name="BossCareTip"}
local My = BossCareTip;
local GO = UnityEngine.GameObject;
local GoList = {};

My.id=""

function My:InitCustom( )
    local TF=TransTool.Find;
    local tip = self.Name;
    local CG = ComTool.Get;
    local root = TF(self.root,"point",tip);
    self.root=root;
    self.item=TransTool.FindChild(root,"item");
    BossCareItem:Init(self.item)
    -- EventMgr.Add("OnChangeScene", My.changesence)
end
function My.changesence(  )
    if NetBoss.careType==0 and My.id~="" and  NetBoss.CareCanClose==false  then
        local scene = User.instance.SceneId;
        local sceneinfo = SceneTemp[tostring(scene)];
        if sceneinfo==nil then
            return
        end
        local bcare =sceneinfo.BossCare==1 and true or false
        if bcare then
            UIMgr.Open(BossCareTip.Name);
        end
    end
end
--打开
function My:Open( )
    UIBase.Open(self);
    -- local id =tostring(NetBoss.CareRelife);
    -- if id==My.id then
    --   return
    -- end
    -- My.id=id
    local info=SBCfg[My.id];
    if info==nil then
        return;
    end
    self:initItem(My.id,info); 
end

function My:initItem( id ,info )
    BossCareItem:ReShow(id ,info)
end

function My:doClose( )
    if LuaTool.IsNull(self.gbj) then return end
    local strid = tostring(NetBoss.CareRelife);
    if strid==My.id or NetBoss.CareCanClose then
        NetBoss.careType = 1;
        My.id=""
        BossCareItem:Clear()
        self.gbj:SetActive(false);
        self:Close();
    elseif My.id ~="" then 
        NetBoss.careType = 0; 
    end
end
-- --禁止关闭
-- function My:ConDisplay()
--     do return true end
-- end

function My:Clear( )
    -- if isReconnect then
    --     return
    -- end
    -- if LuaTool.IsNull(self.gbj) then
    --     self.active = 0
    --     Destroy(self.gbj)
    --     AssetMgr:Unload(self.Name..".prefab")
    --     UIMgr.Dic[self.Name]=nil
    -- end
end

return My;
