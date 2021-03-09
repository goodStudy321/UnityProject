--[[
 	authors 	:Liu
 	date    	:2019-7-30 19:35:00
 	descrition 	:丹药Tip
--]]

UIElixirTip = UIBase:New{Name = "UIElixirTip"}

local My = UIElixirTip

local Btns={}

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.bg = CG(UISprite, root, "tipBg/top/bg")
    self.lab1 = CG(UILabel, root, "tipBg/top/lab1")
    self.lab2 = CG(UILabel, root, "tipBg/top/lab2")
    self.lab3 = CG(UILabel, root, "tipBg/top/lab3")
    self.des1 = CG(UILabel, root, "tipBg/des1")
    self.grid = CG(UIGrid, root, "tipBg/des2/Grid")
    self.cellTran = Find(root, "tipBg/top/cell", des)
    self.item = FindC(root, "tipBg/des2/Grid/lab", des)
    self.item:SetActive(false)

    --操作按钮
	self.Btn=CG(UIGrid,self.root,"Btn",self.Name,false)

    SetB(root, "box", des, self.Close, self)
end

--更新数据
function My:UpData(obj)
    if(type(obj)=="table")then 
        self.tb=obj
        self.type_id = obj.type_id
    elseif(type(obj)=="string")then
        self.type_id = tonumber(obj)
    end
    local key = tostring(self.type_id)
    local item = ItemData[key]
    local cfg = ElixirCfg[key]
    if item==nil or cfg==nil then return end
    self:UpCell(self.type_id)
    self:UpLab(item, cfg)
    self:SetBg(item)
    self:UpPros(cfg)
end

--更新道具
function My:UpCell(id)
    if self.cell == nil then
        self.cell = ObjPool.Get(Cell)
        self.cell:InitLoadPool(self.cellTran, 0.9)
    end
    self.cell:UpData(id)
end

--更新文本
function My:UpLab(item, cfg)
    local id = (cfg.type==0) and cfg.condList[1].k or nil
    local rCfg = RobberyMgr:GetCurCfg(id)
    local str1 = (cfg.type==0) and "境界" or "等级"
    local str2 = (cfg.type==0) and rCfg.floorName or "1级"
    local color = UIMisc.LabColor(item.quality)
    self.lab1.text = string.format("%s%s", color, item.name)
    self.lab2.text = string.format("[F4DDBDFF]%s  [00FF00FF]%s", str1, str2)
    self.lab3.text = string.format("[F4DDBDFF]类型  [00FF00FF]丹药")
    self.des1.text = item.des
end

--更新属性
function My:UpPros(cfg)
    local CGS = ComTool.GetSelf
    local Add = TransTool.AddChild
    for i=1, ElixirMgr.maxProCount do
        local proList = cfg["pro"..i]
        if #proList > 0 then
            local id = proList[1]
            local val = proList[2]
            if val == nil then break end
            local info = PropName[id]
            if info == nil then return end
            local go = Instantiate(self.item)
            local tran = go.transform
            local lab = CGS(UILabel, tran, des)
            local valStr = (info.show==1) and (val/10000*100).."%" or val
            Add(self.grid.transform, tran)
            lab.text = string.format("%s  %s", info.name, valStr)
            go:SetActive(true)
        end
    end
    self.grid:Reposition()
end

--根据品质设置背景
function My:SetBg(item)
    local qua = item.quality
    if qua == 1 then
        self.bg.spriteName = "cell_a01"
    elseif qua == 2 then
        self.bg.spriteName = "cell_a02"
    elseif qua == 3 then
        self.bg.spriteName = "cell_a03"
    elseif qua == 4 then
        self.bg.spriteName = "cell_a04"
    elseif qua == 5 then
        self.bg.spriteName = "cell_a05"
    end
end

function My:ShowBtn(btnList)
	if(btnList==nil)then return end
    for i,btnName in ipairs(btnList) do
		local btn = TransTool.FindChild(self.Btn.transform,btnName)
		btn:SetActive(true)
		local func=self[btnName]
		if not func then iTrace.eError("SJ"," btnName: "..btnName) return end
		UITool.SetBtnSelf(btn,self[btnName],self,self.Name)
		Btns[#Btns+1]=btn
	end
	self.Btn:Reposition()
end

--取出
function My:GetOut()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(tp,1,self.tb.id)
	self:Close()
end

--放入
function My:PutIn()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(1,2,self.tb.id)
	self:Close()
end

--使用
function My:Use()
    UIElixir.selectId = self.type_id
    UIRole:SelectOpen(5)
    self:Close()
end

--获取途径
function My:GetWay()
	GetWayFunc.ItemGetWay(self.type_id)
end

--清空道具
function My:ClearCell()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
        self.cell = nil  
    end
end

--清理缓存
function My:Clear()
    self:ClearCell()
end

--重写释放资源
function My:DisposeCustom()

end

return My
