PkDescInfo = {Name = "PkDescInfo"}
local My = PkDescInfo;
local GO = UnityEngine.GameObject;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:SetPro();
    return o;
end

function My:SetPro()
    self.RwdCells = {};
end

function My:Init(go,parent,index)
    self.root = self:CloneGo(go,parent);
    local root = self.root.transform;
    local name = root.name;
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    self.BG = CG(UISprite,root,"BG",name,false);
    self.Dan = CG(UILabel,root,"Dan",name,false);
    self.Score = CG(UILabel,root,"Score",name,false);
    self.UITable = CG(UITable,root,"ItemTable",name,false);
    self.Done = CG(UISprite,root,"Done",name,false);
    self.RcvBtn = TF(root,"RcvBtn",name);
    self.RcvBtn.gameObject:SetActive(false)
    -- UC(root,"RcvBtn",name,self.RcvBtnC,self);
    self:SetBG(index);
end

function My:CloneGo(go,parent)
    local root = GO.Instantiate(go);
    root.name = go.name;
    root.transform.parent = parent;
    root.transform.localScale = Vector3.one;
    root.gameObject:SetActive(true);
    return root;
end

function My:SetBG(index)
    local num,lnum = math.modf(index/2);
    if lnum == 0 then
        self.BG.spriteName = "";
    else
        self.BG.spriteName = "rank_info_b";
    end
end

function My:SetData(dan,index)
    if dan == nil then
        return;
    end
    self.DanInfo = dan;
    local scoreStr = tostring(dan.score);
    local indStr = tostring(index);
    self.root.name = indStr;
    self.Dan.text = dan.danName;
    self.Score.text = scoreStr;
    -- self:SetRwd();
    -- self:SetRcv();
end

--点击领取
function My:RcvBtnC(go)
    -- if self.DanInfo == nil then
    --     return;
    -- end
    -- Peak.ReqSoloDanRwd(self.DanInfo.danId);
end

--设置领取信息
function My:SetRcv()
    -- if Peak.RoleInfo.score < self.DanInfo.score then
    --     self:SetRcvState(false);
    --     self.Done.spriteName = "ty_undone";
    --     return;
    -- end
    -- local rcv = Peak.DanRwdLst[self.DanInfo.danId];
    -- if rcv == nil then
    --     self:SetRcvState(true);
    -- else
    --     self:SetRcvState(false);
    --     self.Done.spriteName = "ty_done";
    -- end
end

--设置领取状态
function My:SetRcvState(state)
    -- self.RcvBtn:SetActive(state);
    -- self.Done.gameObject:SetActive(not state);
end

--加载掉落格子完成
function My:LoadCD(go)
    self.DrpLCN = self.DrpLCN + 1;
    if self.DrpLCN < self.DrpN then
        return;
    end
    self.UITable:Reposition();
end

--设置掉落物
function My:SetRwd()
    -- self.DrpN = 0;
    -- self.DrpLCN = 0;
    -- local rwds = self.DanInfo.rwdItems;
    -- self.DrpN = #rwds;
    -- if self.DrpN == 0 then
    --     return;
    -- end
    -- local it = nil;
    -- for i = 1, self.DrpN do
    --     it = ObjPool.Get(UIItemCell);
    --     self.RwdCells[i] = it;
    --     it:InitLoadPool(self.UITable.transform,0.6,self)
    --     it:UpData(rwds[i].k,rwds[i].v)
    -- end
end

--销毁掉落物图片
function My:ClearRwd()
    -- if self.RwdCells == nil then
    --     return;
    -- end
    -- local length = #self.RwdCells;
    -- if length == 0 then
    --     return;
    -- end
    -- local dc = nil;
    -- for i = 1, length do
    --     dc = self.RwdCells[i];
    --     dc:DestroyGo();
    --     ObjPool.Add(dc);
    --     self.RwdCells[i] = nil;
    -- end
end

function My:Clear()
    self.root.transform.parent = null;
    -- self:ClearRwd();
    GO.Destroy(self.root);
    TableTool.ClearUserData(self);
end