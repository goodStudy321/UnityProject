--[[
    奖励项
]]

HotLoveItem = Super:New{Name = "HotLoveItem"};
local My = HotLoveItem;

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.cellList = {}
    self.go = root.gameObject
    self.lab = CG(UILabel, root, "Des")
    self.btn = FindC(root, "Btn", des)
    self.yes = FindC(root, "yes", des)
    self.no = FindC(root, "no", des)
    self.grid = Find(root, "Grid", des)

    SetB(root, "Btn", des, self.OnBtn, self)
    self.cfg = cfg;
    
    self:ChangeName()
    self:InitCell()
    self:InitDesLab()
    self:UpBtnState()
    self:SetLuaLsnr("Add");
end


function My:SetLuaLsnr(fn)
    HotLoveMgr.eUpdateAward[fn](HotLoveMgr.eUpdateAward , self.UpdateAward, self);
    HotLoveMgr.eUpdateBtn[fn](HotLoveMgr.eUpdateBtn , self.UpdateBtn, self);
end

function My:UpdateAward(data)
    if data.id == self.cfg.id then
        self.cfg = data;
        self:ChangeName()
        --self:InitCell()
        self:InitDesLab()
        self:UpBtnState()
    end
end



--点击领取
function My:OnBtn()
    HotLoveMgr:ReqAward(self.cfg.id);
end

--显示按钮状态
function My:UpBtnState()
    local state = self.cfg.state;
    if state == 1 then
        self:ShowBtnState(true, false, false)
    elseif state == 2 then
        self:ShowBtnState(false, true, false)
    elseif state == 3 then
        self:ShowBtnState(false, false, true)
    end
end


function My:UpdateBtn()
    if self.cfg.state ~= 3 then
        if HotLoveMgr.money >= self.cfg.needNum then
            self:ShowBtnState(false, true, false);
        end
    end
end

--更新按钮状态
function My:ShowBtnState(state1, state2, state3)
    self.no:SetActive(state1)
    self.btn:SetActive(state2)
    self.yes:SetActive(state3)
end

--更新道具
function My:InitCell()
    local cfg = self.cfg;
    for i,v in ipairs(cfg.awards) do
        local cell = ObjPool.Get(UIItemCell);
        cell:InitLoadPool(self.grid, 0.8);
        cell:UpData(v.I, v.B, v.N);
        table.insert(self.cellList, cell);
    end
end

--初始化描述文本
function My:InitDesLab()
    local num = self.cfg.needNum;
    self.lab.text = StrTool.Concat(tostring(num), "热点可领取:");
end

--改变名字
function My:ChangeName()
    local num = 0
    local cfg = self.cfg
    if cfg.state == 1 then
        num = cfg.id + 5000
    elseif cfg.state == 2 then
        num = cfg.id + 1000
    elseif cfg.state == 3 then
        num = cfg.id + 8000
    end
    self.go.name = num
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
    self:SetLuaLsnr("Remove");
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My;