require("UI/UIArena/OlRkRwdItem")
UIRankRwd = {Name = "UIRankRwd"}
local My = UIRankRwd;

My.RankItem = nil;
My.RwdDesc = nil;
My.UITable = nil;
My.RkItms = {}

--打开奖励UI
function My:Open(rwdTable)
    if rwdTable == nil then
        return;
    end
    local len = #rwdTable;
    if len == 0 then
        return;
    end

    local trans = UIArena.RankRwd.transform;
    local name = trans.name;
    UIArena.RankRwd:SetActive(true);

    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;

    My.RwdDesc = CG(UILabel,trans,"RwdDesc",name,false);
    My.UITable = CG(UITable,trans,"ScrollView/Grid",name,false);
    My.RankItem = TF(trans,"ScrollView/Grid/RankItem",name,false);
    My.RankItem:SetActive(false);
    UC(trans,"CloseBtn",name,self.CloseC,self);

    for i = 1,len do
        local item = ObjPool.Get(OlRkRwdItem);
        item:SetInfo(My.RankItem,rwdTable[i],i);
        My.RkItms[i] = item;
    end
    My.UITable:Reposition();
end

--清除奖励条
function My:ClearRkItms()
    local len = #My.RkItms;
    if len == 0 then
        return;
    end
    for i = 1, len do
        local item = My.RkItms[i];
        item:Clear();
        ObjPool.Add(item);
        My.RkItms[i] = nil;
    end
end

--点击关闭
function My:CloseC()
    UIArena.RankRwd:SetActive(false);
    self:ClearRkItms();
    TableTool.ClearUserData(self);
end