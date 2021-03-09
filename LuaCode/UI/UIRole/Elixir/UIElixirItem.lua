--[[
 	authors 	:Liu
 	date    	:2019-7-23 11:30:00
     descrition :丹药项
--]]

UIElixirItem = Super:New{Name = "UIElixirItem"}

local My = UIElixirItem

function My:Init(root, cfg)
    local des = self.Name
    local SetS = UITool.SetBtnSelf
    local FindC = TransTool.FindChild

    self.cfg = cfg
    self.root = root
    self.count = 0
    self.curMark = false

    self.spr = FindC(root, "spr", des)
    self.mark = FindC(root, "mark", des)
    self.red = FindC(root, "Red", des)
    --self.red:SetActive(false);

    SetS(root, self.OnClick, self)

    self:UpCell()
end

--点击丹药
function My:OnClick()
    if self.curMark == false then
        UIElixir.pop:UpData(self.cfg, self.count)
        UIElixir:UpCurMarkState(UIElixir.curIt, false)
        UIElixir:UpCurMarkState(self, true)
    end
end

--更新高亮状态
function My:UpMarkState(state)
    self.mark:SetActive(state)
end

--更新道具
function My:UpCell()
    local cfg = self.cfg
    local count = ItemTool.GetNum(cfg.id)
    local color = (count<1) and "[F21919FF]" or "[00FF00FF]"
    
    
    local countStr = string.format("%s%s", color, count)
    local isActive = ElixirMgr:IsActive(cfg.id) or (count > 0)
    --local num = (isActive==true or count>0) and 1 or 0
    --local val = (isActive==true) and 2 or 255
    local num =   1
    local val =  2
    if self.cell == nil then
        self.cell = ObjPool.Get(Cell)
        self.cell:InitLoadPool(self.root, 0.9)
    end
    self.cell:UpData(cfg.id, countStr, isActive)
    self:UpCellState(num)
    self:UpLock(val)
    --self:UpAction();
    self.count = count
    self:UpShowSpr(cfg)
end

--显示红点
function My:UpAction()
    local cfg = self.cfg;
    if cfg.type == 1 then return end
    local isMax = ElixirMgr:IsMax(cfg.id, cfg.max, cfg.type, cfg.time, cfg.max);
    local rCfg = RobberyMgr:GetCurCfg();
    local id = 0;
    if (cfg.condList[#cfg.condList]) then
        id = cfg.condList[#cfg.condList].k
    end
     
    if (isMax == false) and (rCfg.id >= id) and (self.count > 0)then
        self.red:SetActive(true);
    else
        self.red:SetActive(false);
    end
end


--更新贴图显示
function My:UpShowSpr(cfg)
    if cfg.type == 1 then
        local sec = ElixirMgr:GetElixirTime(cfg.id)
        self.spr:SetActive(sec>0)
    end
end

--更新道具状态
function My:UpCellState(num)
    local tran = self.cell.Icon.transform
    local wdg = tran:GetComponent(typeof(UIWidget))
    if wdg == nil then return end
    local color = wdg.color
	color.r = num
    wdg.color = color
end

--更新上锁状态
function My:UpLock(val)
    self.cell.lock.color = Color.New(255, 255, 255, val) / 255.0
end

--清空道具
function My:ClearCell()
    if self.cell then
        self:UpCellState(1)
        self:UpLock(2)
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil  
    end
end

--清理缓存
function My:Clear()
    self.count = 0
    self.curMark = false
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:ClearCell()
end

return My