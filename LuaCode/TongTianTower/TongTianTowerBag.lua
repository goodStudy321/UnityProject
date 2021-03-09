--[[
    通天宝塔背包
]]

TongTianTowerBag = Super:New{Name = "TongTianTowerBag"};

local My = TongTianTowerBag;

function My:Init(root)
    local des = self.Name;
    local TFC = TransTool.FindChild;
    local USC = UITool.SetLsnrClick;

    self.go = root.gameObject;
    self.bagTran = TFC(root, "bg3");
    USC(root, "CloseBtn", des, self.OnClose, self);
    self.bag = nil;
    self:InitBag();
end


--初始化背包
function My:InitBag()
    self.bag = ObjPool.Get(CellUpdate);
    self.bag:Init(self.bagTran);
    self.bag:InitData(8);
end

--获取背包剩余空格
function My.GetBagCell()
    local num = 0;
    local bag = PropMgr.tb8Dic;
    for k,v in pairs(bag) do
        num = num + 1;
    end
	return PropMgr.cellNumDic["8"]-num;
end


--更新显示
function My:UpShow(state)
    self.go:SetActive(state);
end

--点击关闭
function My:OnClose()
    self:UpShow(false);
    UITongTianTower:ModelShow(true);
    UITongTianTower:UpdateAction();
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self);
end
    
--释放资源
function My:Dispose()
    self:Clear();
    ObjPool.Add(self.bag);
    self.bag = nil;
end

return My;