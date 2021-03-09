require("UI/UIArena/PkDescInfo")
UIPeakDesc = {Name = "UIPeakDesc"}
local My = UIPeakDesc;
My.DanItems = {}

function My:Open(go)
    go:SetActive(true);
    self.root = go;
    local root = go.transform;
    local name = go.name;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;
    local grid = CG(UIGrid,root,"scrollV/grid",name)
    local trans = grid.transform
    self.DanDesc = TF(root,"DanDesc",name);
    self.PlayDesTgl = CG(UIToggle,trans,"PlayDescBtn",name,false);
    self.NeedLev = CG(UILabel,root,"PlayDesc/NeedLevel",name,false);
    self.OpenTime = CG(UILabel,root,"PlayDesc/OpenTime",name,false);
    self.BattleRule = CG(UILabel,root,"PlayDesc/BattleRule",name,false);
    self.UITable = CG(UITable,root,"DanDesc/Table",name,false);
    self.Item = TF(root,"DanDesc/Table/Item",name);
    self.Item:SetActive(false);
    UC(root,"CloseBtn",name,self.Close,self);
    UC(trans,"PlayDescBtn",name,self.SetPlayDesc,self);
    self.BronB = TF(trans,"BronzeBtn",name);
    self.Sliver = TF(trans,"SliverBtn",name);
    self.Gold = TF(trans,"GoldBtn",name);
    self.Platinum = TF(trans,"PlatinumBtn",name);
    self.Diamonds = TF(trans,"DiamondsBtn",name);
    local index = UIArena.index;
    if index == 2 then
        self:SetBtnShow(true);
        UC(trans,"BronzeBtn",name,self.SetDanDesc,self);
        UC(trans,"SliverBtn",name,self.SetDanDesc,self);
        UC(trans,"GoldBtn",name,self.SetDanDesc,self);
        UC(trans,"PlatinumBtn",name,self.SetDanDesc,self);
        UC(trans,"DiamondsBtn",name,self.SetDanDesc,self);
    else
        self:SetBtnShow(false);
    end
    self:SetPlayDesc();
    self:AddLsnr();
    grid:Reposition()
end

function My:AddLsnr()
    -- Peak.eDanRwdList:Add(self.RfrDanRwdGet,self);
end

function My:RmLsnr()
    -- Peak.eDanRwdList:Remove(self.RfrDanRwdGet,self);
end

--设置按钮显示
function My:SetBtnShow(state)
    self.DanDesc:SetActive(state);
    self.BronB:SetActive(state);
    self.Sliver:SetActive(state);
    self.Gold:SetActive(state);
    self.Platinum:SetActive(state);
    self.Diamonds:SetActive(state);
end

--设置玩法说明
function My:SetPlayDesc(go)
    self.PlayDesTgl.value = true;
    self.DanDesc:SetActive(false);
    local actId = UIArena.ActiveIds[UIArena.index];
    local info = ActiveInfo[tostring(actId)];
    if info == nil then
        return;
    end
    self.NeedLev.text = string.format("%s级",info.needLv);
    self.BattleRule.text = info.desc;
    self.OpenTime.text = UIArena.GetActTime();
end

--设置段位说明
function My:SetDanDesc(go)
    if go.name == "BronzeBtn" then
        self:SetDan(1);
    elseif go.name == "SliverBtn" then
        self:SetDan(2);
    elseif go.name == "GoldBtn" then
        self:SetDan(3);
    elseif go.name == "PlatinumBtn" then
        self:SetDan(4);
    elseif go.name == "DiamondsBtn" then
        self:SetDan(5);
    end
end

function My:SetDan(type)
    self:ClearDanItems();
    local index = 1;
    for k,v in pairs(OvODanRwd) do
        if v.danType == type then
            if My.DanItems[index] == nil then 
                local info = PkDescInfo:New();
                info:Init(self.Item,self.UITable.transform,index);
                info:SetData(v,index);
                My.DanItems[index] = info;
            else
                My.DanItems[index]:SetData(v,index);
            end
            index = index + 1;
        end
    end
    self.UITable:Reposition();
end

--刷新段位奖励领取
function My:RfrDanRwdGet()
    -- for k,v in pairs(My.DanItems) do
    --     v:SetRcv();
    -- end
end

function My:ClearDanItems()
    for k,v in pairs(My.DanItems) do
        v:Clear();
        My.DanItems[k] = nil;
    end
end

--关闭面板
function My:Close()
    self:RmLsnr();
    self:ClearDanItems();
    self.root:SetActive(false);
    TableTool.ClearUserData(self);
end