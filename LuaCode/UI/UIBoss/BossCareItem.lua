BossCareItem =Super:New{ Name = "BossCareItem" }
local My = BossCareItem;

function My:Init(go)
    self.go=go;
    local root = go.transform;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local tip = self.Name;
    self.icon=CG(UITexture,root,"icon",tip);
    self.info=CG(UILabel,root,"info/name",tip);
    UC(root,"btn/close",tip,self.Close,self);
    UC(root,"btn/ok",tip,self.toUI,self);
    self.iconText="";
    -- self.Timer = ObjPool.Get(DateTimer);
    -- self.Timer.complete:Add(self.EndTime, self);
end
--刷新展示
function My:ReShow(id,info)
    self.id=id;
    -- self.type=type;   

    if info.what==0 then
        local mt = MonsterTemp[id];
        if mt==nil then
            return;
        end
        self.iconText=mt.icon;
        local lv =  mt.level;
        local name = mt.name;
        self.info.text= string.format( "%s级%s",lv,name);
    elseif info.what==2 then
        local mt = MonsterTemp[id];
        if mt==nil then
            return;
        end
        self.iconText=mt.icon;
        local name = mt.name;
        self.info.text= string.format( "%s",name);
    elseif info.what==1 then
        local mt = BinTool.Find(CollectionTemp,tonumber(id));
        if mt==nil then
            return;
        end
        self.iconText=mt.icon..".png";
        local name = mt.name;
        self.info.text= string.format( "%s",name);
    end
    AssetMgr:Load(self.iconText,ObjHandler(self.LoadIcon,self));

    --一分钟倒计时Do
    -- self:SetTime()
end
-- function My:SetTime()
-- 	if self.Timer == nil then
-- 		return;
-- 	end
-- 	self.Timer.seconds = 60;
-- 	self.Timer.cnt = 0;
-- 	self.Timer:Start();
-- end
function My:Unload( ... )
    AssetMgr:SetPersist(self.iconText,false)
    AssetMgr:Unload(self.iconText,false);
    self.iconText="";
end

--加载icon完成
function My:LoadIcon(obj)
    self.icon.mainTexture=obj;
    AssetMgr:SetPersist(self.iconText,true)
end
--跳转bossui
function My:toUI( )
    self:Close();
    BossHelp.ChoseBossCellAndOpen(self.id)
end

function My:Close( )
    BossCareTip:doClose();
end

function My:Clear( )
    self:Unload( )
end

return My;