RecordItem =Super:New{ Name = "RecordItem" }
local My = RecordItem;
local GO = UnityEngine.GameObject;
My.type=1
function My:Init(go,type,name)
    My.type=type
    self.root = go;
    local name = go.name;
    self.GoName=name
    local trans = go.transform;
    local TF = TransTool.Find;
    local CG = ComTool.Get;
    self.tit = CG(UILabel,trans,"tit",name,false);
    self.msg = CG(UILabel,trans,"msg",name,false);
    if type==1 then
        self.ItemRoot = TF(trans,"item",name);
    end
end

--设置内容
function My:SetContext(info)
    local mapName = self:GetMapName(info.mapId);
    local monsInfo = self:GetMonsName(info.monsTypeId);
    local monsName = monsInfo.name
    local monsLvl = monsInfo.level
    local role = info.roleName
    local itemTypeId = info.itemTypeId
    local itemInfo = UIMisc.FindCreate(itemTypeId)
    if itemInfo==nil then
        iTrace.Error("soon","未找到道具id="..itemTypeId)
        return;
    end
    local itemName = itemInfo.name
    local qua = UIMisc.LabColor(itemInfo.quality)
    local p_sb = ObjPool.Get(StrBuffer)
    local time = info.time
    p_sb:Apd( "【"):Apd(mapName):Apd("】")
    if My.type==1 then
        local date = DateTool.GetDate(time)
        local Hour = date.Hour 
        local Minute = date.Minute
        if Hour<10 then
            Hour="0"..tostring(Hour)
        end
        if Minute<10 then
            Minute="0"..tostring(Minute)
        end
        p_sb:Apd(" "):Apd(date.Year):Apd("年"):Apd(date.Month):Apd("月"):Apd(date.Day):Apd("日")
        :Apd(" "):Apd(Hour):Apd(":"):Apd(Minute)
        self:SetItem(itemTypeId);
    end
    local strtit =p_sb:ToStr()
    self.tit.text=strtit
    p_sb:Dispose()
    p_sb:Apd("[00FF00FF]"):Apd(role):Apd("[-][99886BFF]击败")
    :Apd(monsName):Apd(",获得了[-]"):Apd(qua):Apd(itemName):Apd("[-]")
    local strmsg =p_sb:ToStr()
    self.msg.text=strmsg
    ObjPool.Add(p_sb);
end

--获取怪物名
function My:GetMonsName(monsTypeId)
    local info = MonsterTemp[tostring(monsTypeId)];
    if info == nil then
        iTrace.eError("xiaoyu","怪物配置为空 id: "..monsTypeId)
        return nil;
    end
    return info;
end

--获取地图名
function My:GetMapName(mapId)
    local info = SceneTemp[tostring(mapId)];
    if info == nil then
        return nil;
    end
    return info.name;
end

--设置获得物品
function My:SetItem(itemTypeId)
    local item = ObjPool.Get(UIItemCell);
    item:InitLoadPool(self.ItemRoot,0.8);
    item:UpData(itemTypeId);
    self.Item = item;
end


--销毁记录
function My:Dispose()
    -- soonTool.desOneCell(self.Item)
    if self.root == nil then
        return;
    end
    soonTool.Add(self.root,self.GoName,true)
end