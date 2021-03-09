UIFiveElmntRwd = {Name = "UIFiveElmntRwd"}
local My = UIFiveElmntRwd;
My.DropCells = {}

function My:Init(trans)
    self.root = trans.gameObject;
    local name = trans.name;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;

    self.Table = CG(UITable,trans,"ScrollView/Table",name,false);
    UC(trans,"CloseBtn",name,self.Close,self);
    UC(trans,"SecretBtn",name,self.SecretClk,self);
    self:SetGoActive(self.root,false);
end

--初始化格子
function My:InitCells()
    local it = nil;
    for k,v in pairs(FiveElmtMgr.DropList) do
        it = ObjPool.Get(UIItemCell);
        My.DropCells[k] = it;
        it:InitLoadPool(self.Table.transform,0.9,self);
        it:UpData(k,v);
        local name = My.GetRankName(k);
        it.trans.name = name;
    end
end

--获取排序名字
function My.GetRankName(dropId)
    dropId = tostring(dropId);
    local info = SMSProTemp[dropId];
    if info == nil then
        return "99999";
    end
    --反向排序，根据高品质为优先，星级高次之
    local num = (9 - info.quality) * 10 + (9 - info.star);
    return tostring(num);
end

--加载掉落格子完成
function My:LoadCD(go)
    self.Table.repositionNow = true;
end

--打开界面
function My:Open()
    self:SetGoActive(self.root,true);
    self:InitCells();
end

--关闭
function My:Close()
    self:SetGoActive(self.root,false);
    self:ClearCells();
end

--天机印按钮点击
function My:SecretClk()
    UIMgr.Open(UISkyMysterySeal.Name);
end

--设置对象状态
function My:SetGoActive(go,active)
    if go == nil then
        return;
    end
    go:SetActive(active);
end

--清除格子
function My:ClearCells()
    local cells = My.DropCells;
    if cells == nil then
        return;
    end
    for k,v in pairs(cells) do
        v = My.DropCells[k];
        v:DestroyGo();
        ObjPool.Add(v);
        self.DropCells[k] = nil;
    end
end

function My:Dispose()
    self:ClearCells();
end