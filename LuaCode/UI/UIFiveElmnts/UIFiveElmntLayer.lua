require("UI/UIFiveElmnts/FElmntLayInfo")
UIFiveElmntLayer = { Name = "UIFiveElmntLayer"}
local My = UIFiveElmntLayer;
local GO = UnityEngine.GameObject;
--条目字典
My.ItemDic = {}

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.Table = CG(UITable,trans,"ScrollView/Table",name,false);
    self.LayerItem = TFC(trans,"ScrollView/Table/LayerItem",name);
    UC(trans,"CloseBtn",name,self.Close,self);

    self:SetGoActive(self.LayerItem,false);
    self:SetGoActive(self.root,false);
end

--打开界面
function My:Open()
    self:SetGoActive(self.root,true);
    self:ShowLayers();
end

--关闭
function My:Close()
    self:SetGoActive(self.root,false);
    self:ClearItems();
end

--显示层
function My:ShowLayers()
    local maxId = FiveElmtMgr.curMaxCopyId;
    local fstId = 70001;
    local openNum = maxId - fstId;
    local count = openNum;
    if openNum >= 5 then
        count = 4;
    end
    for i = 0,count do
        local mapId = maxId - i;
        self:CreateItem(mapId,i);
    end
    self.Table:Reposition();
end

--创建条目
function My:CreateItem(mapId,index)
    local go = self:CloneItem();
    go.name = tostring(index);
    local info = ObjPool.Get(FElmntLayInfo);
    info:SetData(go,mapId);
    My.ItemDic[index] = info;
end

--销毁条目
function My:ClearItems()
    TableTool.ClearDicToPool(My.ItemDic);
end

--设置对象状态
function My:SetGoActive(go,active)
    if go == nil then
        return;
    end
    go:SetActive(active);
end

--克隆对象
function My:CloneItem()
    local go = self.LayerItem;
    local root = GO.Instantiate(go);
    local parent = self.LayerItem.transform.parent;
    TransTool.AddChild(parent,root.transform);
    root.gameObject:SetActive(true);
    return root;
end