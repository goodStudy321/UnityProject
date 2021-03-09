UICopyFvElmnt = UICopyInfoBase:New{Name = "UICopyFvElmnt"}
local My = UICopyFvElmnt;
local GO = UnityEngine.GameObject;
--奖励表
My.rwds = {}
My.RewardCells = {}

function My:InitSelf()
    local CG = ComTool.Get;
    local trans = self.left;
    self.Title = CG(UILabel, trans, "Name");
    self.TarDes = CG(UILabel, trans, "Target");
    self.RwdDes = CG(UILabel, trans, "Lab_2");
    self.RwdTbl = CG(UITable, trans, "ScrollView/RwdTable");
end

--初始化数据
function My:InitData()  
    local temp = self.Temp;
    local mapId = tostring(temp.id);
    local fvElmnt = FvElmntCfg[mapId];
    if fvElmnt == nil then
        return;
    end
    self:DisposeSelf();
    self.fvCfg = fvElmnt;
    self.Title.text = fvElmnt.name;
    self:UpdateSub();
    self:SetRwdDes();
    self:SetRwds();
    self:ShowRwds();
end

--显示奖励
function My:ShowRwds()
    local it = nil;
    local i = 1;
    for id,num in pairs(My.rwds) do
        it = ObjPool.Get(UIItemCell);
        self.RewardCells[i] = it;
        it:InitLoadPool(self.RwdTbl.transform,0.6,self);
        it:UpData(id,num);
        i = i + 1;
    end
end

--设置奖励
function My:SetRwds()
    local isFP = self:IsFirstBat();
    if isFP == true then
        for k,v in pairs(self.fvCfg.fpRwds) do
            My.rwds[v.k] = v.v;
        end
    else
        for k,v in pairs(self.fvCfg.nmlRwds) do
            My.rwds[v] = 1;
        end
    end
end

--设置奖励描述
function My:SetRwdDes()
    local isFP = self:IsFirstBat();
    local des = nil;
    if isFP == true then
        des = "首次通关科获得以下奖励：";
    else
        des = "通关几率获得以下奖励：";
    end
    self.RwdDes.text = des;
end

--是否首次通关
function My:IsFirstBat()
    TableTool.ClearDic(My.rwds);
    local curId = self.fvCfg.id; 
    local passMapId = FiveElmtMgr.curMaxCopyId;
    if passMapId < curId then
        return true;
    end
    return false;
end

--加载奖励格子完成
function My:LoadCD(go)
    self.RwdTbl:Reposition();
end

--更新当前进度
function My:UpdateSub()
    local info = CopyMgr.CopyInfo;
    local monsId = tostring(self.fvCfg.monsId);
    local monsNum = self.fvCfg.monsNum;
    local mt = MonsterTemp[monsId];
    local name = mt and mt.name or "怪物";
    local des = string.format("击败[00FF00FF]%s[-] %d/%d", name, info.Sub or 0, monsNum);
    self.TarDes.text = des;
end

--释放
function My:DisposeSelf()
    TableTool.ClearDic(self.rwds);
    TableTool.ClearListToPool(self.RewardCells);
end

return My