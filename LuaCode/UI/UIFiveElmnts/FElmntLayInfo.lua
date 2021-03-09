FElmntLayInfo = Super:New{ Name = "FElmntLayInfo"}
local My = FElmntLayInfo;

--设置数据
function My:SetData(go,mapId)
    self.root = go;
    self.mapId = mapId;
    local trans = go.transform;
    local name = trans.name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local UCS = UITool.SetLsnrSelf;

    self.LayerName = CG(UILabel,trans,"LayerName",name,false);
    self.Select = TFC(trans,"Select",name);
    UCS(go,self.SelectClk,self,name);

    self:SetLayerName();
    self:SetSltFlag();
end

--设置层名
function My:SetLayerName()
    local cfg = CopyTemp[tostring(self.mapId)];
    if cfg == nil then
        return;
    end
    self.mapName = cfg.name;
    self.LayerName.text = cfg.name;
end

--设置选择标识
function My:SetSltFlag()
    if self.mapId == User.SceneId then
        self.Select:SetActive(true);
    else
        self.Select:SetActive(false);
    end
end

--选择点击
function My:SelectClk(go)
    if self.mapId == User.SceneId then
        UITip.Log("已在本层，无法前往")
        return;
    end
    local msg = string.format("是否前往%s",self.mapName);
    MsgBox.ShowYesNo(msg, self.GoToMap,self);
end

--前往地图
function My:GoToMap()
    UIFiveElmntLayer:Close();
    UIFiveElmntMons:Close();
    UIFiveElmntView:Close();
    SceneMgr:ReqPreEnter(self.mapId,false,true);
end

function My:Dispose()
    local isNull = LuaTool.IsNull(self.root);
    if isNull == false then
        Destory(self.root);
        self.root = nil;
    end
end