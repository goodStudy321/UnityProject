--//市场我要求购物品条目
UIMktIWantList = Super:New{Name = "UIMktIWantList"}

local iLog = iTrace.Log
local iError = iTrace.Error

local M = UIMktIWantList

--//创建控件
-- function M:New(o)
-- 	o = o or {}
-- 	setmetatable(o, self)
-- 	self.__index = self
-- 	return o
-- end

--//初始化
function M:Init(gameObj)
    --//列表条目物体
    self.itemObj = gameObj
	--// 面板transform
    self.rootTrans = self.itemObj.transform
    
    local tip = "UI市场我要求购材料条目"

	local C = ComTool.Get
	local CF = ComTool.GetSelf
    local T = TransTool.FindChild
    
    --// 选择标志
    self.selSign = T(self.rootTrans, "SelSign")
    --// 物品cell父节点
    self.cellParent = T(self.rootTrans, "NameCount/CellCont")
    
    --// 物品名称
    self.itemName = C(UILabel, self.rootTrans, "NameCount/ItemName", tip, false)
    --// 物品品阶
    self.classLb = C(UILabel, self.rootTrans, "Class/ClassLb", tip, false)
    
    self.isSel = false

    UITool.SetLsnrSelf(self.rootTrans,self.ClickSelf,self,nil, false)
end

--// 释放
function M:Dispose()
	if self.item ~= nil then
		self.item:DestroyGo()
		ObjPool.Add(self.item)
		self.item = nil
    end
    self.data = nil
    self.selCallBack = nil
    self.isSel = nil
    TableTool.ClearUserData(self)
end
    
    -- 重置数据
function M:Reset()
    if self.item ~= nil then
		self.item:Clean()
    end
    self.isSel = false
end

--// 链接和初始化配置
function M:InitCfg(tbData,selCB)
    
    self.selCallBack = selCB;
    self.data = tbData

    self.itemName.text = tbData.name
    if tbData.wearRank == nil then
        if tbData.lv ~= nil then
            self.classLb.text = UIMisc.NumToStr(tbData.lv,"阶")
        else
            self.classLb.text = UIMisc.NumToStr(1,"阶")
        end
    else
        self.classLb.text = UIMisc.NumToStr(tbData.wearRank,"阶")
    end
    
    if not self.item then
        self.item=ObjPool.Get(UIItemCell)
        self.item:InitLoadPool(self.cellParent.transform,0.8)
    end
    --self.item:UpData(tbData.id,tbData.num)
    self.item:TipWhat(tbData.id,"",true)
    -- self:SetSel(false)
end

--// 点击自身
function M:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack();
	end
end

--// 显示隐藏
function M:Show(sOh)
	self.itemObj:SetActive(sOh)
end

function M:SetSel(isSel)
	self.isSel = isSel
	self.selSign:SetActive(self.isSel)
end