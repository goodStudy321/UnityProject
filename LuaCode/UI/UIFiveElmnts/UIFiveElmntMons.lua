require("UI/UIFiveElmnts/UIMonsItem")
UIFiveElmntMons = {Name = "UIFiveElmntMons"}
local My = UIFiveElmntMons;
local GO = UnityEngine.GameObject;

My.monsItems = {}

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;

    self.Table = CG(UITable,trans,"ScrollView/Table",name,false);
    self.monsItem = TF(trans,"ScrollView/Table/MonsItem",name);
    self:SetGoActive(self.monsItem.gameObject,false);
end

--设置条目
function My:SetItems()
    local sceneId = User.SceneId;
    local bossInfos = FiveElmtMgr.GetCopyAllMons(sceneId);
    if bossInfos == nil then
        return;
    end
    for k,v in pairs(bossInfos) do
        local go = self:CloneItem();
        local monItem = ObjPool.Get(UIMonsItem);
        monItem:SetInfo(go,v);
        My.monsItems[k] = monItem;
    end
    self.Table.repositionNow = true;
end

--添加监听
function My:AddLsnr()
    local mgr = FiveElmtMgr;
    mgr.eUpdFvElmt:Add(self.UpdateTime,self);
end

--移除监听
function My:RemoveLsnr()
    local mgr = FiveElmtMgr;
    mgr.eUpdFvElmt:Remove(self.UpdateTime,self);
end

--打开界面
function My:Open()
    self:SetItems();
    self:SetGoActive(self.root,true);
    self:AddLsnr();
end

--关闭
function My:Close()
    self:SetGoActive(self.root,false);
    self:RemoveLsnr();
    self:ClearItems();
end

--怪物刷新时间有刷新
function My:UpdateTime(copyId)
    -- body
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
    local go = self.monsItem;
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = go.transform.parent;
    root.transform.localPosition = Vector3.zero;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

--清除条目
function My:ClearItems()
    TableTool.ClearDicToPool(My.monsItems)
end

--释放
function My:Dispose()
    self:ClearItems();
end