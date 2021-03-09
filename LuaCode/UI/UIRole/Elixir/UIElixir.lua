--[[
 	authors 	:Liu
 	date    	:2019-7-23 11:30:00
 	descrition 	:丹药系统
--]]

UIElixir = Super:New{Name = "UIElixir"}

local My = UIElixir

require("UI/UIRole/Elixir/UIElixirItem")
require("UI/UIRole/Elixir/UIElixirPop")
require("UI/UIRole/Elixir/UIElixirProPop")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild
	
	self.itDic = {}
	self.go = root.gameObject
	self.curIt = nil

	self.lvLab = CG(UILabel, root, "Panel/LvLab")
	self.nameLab = CG(UILabel, root, "Panel/NameLab")
	self.grid1 = CG(UIGrid, root, "Scroll View1/Grid")
	self.grid2 = CG(UIGrid, root, "Scroll View2/Grid")
	self.modelTran = Find(root, "modelBox/Model", des)
	self.popTran = Find(root, "Panel/infoPopup", des)
	self.proPopTran = Find(root, "Panel/proPop", des)
	self.item1 = FindC(root, "Scroll View1/Grid/item", des)
	self.item2 = FindC(root, "Scroll View2/Grid/item", des)
	self.modelBox = FindC(root, "modelBox", des)
	self.item1:SetActive(false)
	self.item2:SetActive(false)

	SetB(root, "Panel/btn1", des, self.OnBtn1, self)
	SetB(root, "Panel/btn2", des, self.OnBtn2, self)

	self:InitModuel()
	self:InitItem()
	self:InitLab()
	self:CreateModel()
end

--设置监听
function My:SetLnsr(func)
	ElixirMgr.eUse[func](ElixirMgr.eUse, self.RespUse, self)
	ElixirMgr.eOverdue[func](ElixirMgr.eOverdue, self.RespOverdue, self)
	PropMgr.eUpNum[func](PropMgr.eUpNum, self.RespUpCount, self)
	PropMgr.eRemove[func](PropMgr.eRemove, self.RespRemove, self)
	FashionMsg.eChgFashion[func](FashionMsg.eChgFashion, self.RfRoleMod, self)
end

--响应丹药使用
function My:RespUse(id)
	local it = self.itDic[tostring(id)]
	if it == nil then return end
	it:UpCell()
	self.pop:UpData(it.cfg, it.count)
end

--响应丹药过时
function My:RespOverdue(key)
	local it = self.itDic[key]
	if it == nil then return end
	it:UpCell()
	self.pop:UpData(it.cfg, it.count)
end

--更新丹药数量
function My:RespUpCount(tb)
	local it = self.itDic[tostring(tb.type_id)]
	if it == nil then return end
	it:UpCell()
	-- self:UpSort()
end

--响应丹药移除
function My:RespRemove(id, tb, typeId)
	local it = self.itDic[tostring(typeId)]
	if it == nil then return end
	it:UpCell()
	self.pop:UpData(it.cfg, 0)
	-- self:UpSort()
end

--初始化丹药项
function My:InitItem()
	local Add = TransTool.AddChild
	for k,v in pairs(ElixirCfg) do
		local grid = (v.type==0) and self.grid1.transform or self.grid2.transform
		local item = (v.type==0) and self.item1 or self.item2
		local go = Instantiate(item)
		local tran = go.transform
		go:SetActive(true)
		Add(grid, tran)
		local it = ObjPool.Get(UIElixirItem)
		it:Init(tran, v)
		self.itDic[tostring(k)] = it
	end
	-- self:UpSort()
	-- self:UpSelectData()
end

--更新丹药选中数据
function My:UpSelectData()
	if self.curIt then
		self.pop:UpData(self.curIt.cfg, self.curIt.count)
		self:UpCurMarkState(self.curIt, true)
	end
end

--更新当前高亮状态
function My:UpCurMarkState(curIt, state)
	if curIt == nil then return end
	self.curIt = curIt
	self.curIt.curMark = state
	self.curIt:UpMarkState(state)
end

--更新丹药红点
function My:ElixirRed(cfg)
	self.itDic[tostring(cfg.id)]:UpAction();
end


--更新丹药数据
function My:UpItemData()
	for k,v in pairs(self.itDic) do
		v:UpCell()
		v:UpAction();
	end
end

--更新丹药排序
function My:UpSort()
	self:UpItemName()
	self.grid1:Reposition()
	self.grid2:Reposition()
end

--更新丹药名字
function My:UpItemName()
	local isShow = false
	local list = CustomInfo:SwitchToList(self.itDic)
	table.sort(list, My.ElixirSort)
	for i,v in ipairs(list) do
		v.root.gameObject.name = 1000 + i

		if i == 1 then self.curIt = v end
		if isShow == false then
			isShow = ElixirMgr:IsShowUiAction(v.cfg, v.count)
			if isShow == true then self.curIt = v end
		end
	end
end

--丹药排序
function My.ElixirSort(a, b)
	local cfg1 = a.cfg
	local cfg2 = b.cfg
	local isActive1 = ElixirMgr:IsActive(cfg1.id) or a.count > 0
	local isActive2 = ElixirMgr:IsActive(cfg2.id) or b.count > 0
	local sec1 = ElixirMgr:GetElixirTime(cfg1.id)
	local sec2 = ElixirMgr:GetElixirTime(cfg2.id)
	local isMax1 = ElixirMgr:IsMax(cfg1.id, cfg1.max, cfg1.type, cfg1.time, cfg1.max)
	local isMax2 = ElixirMgr:IsMax(cfg2.id, cfg2.max, cfg2.type, cfg2.time, cfg2.max)
	local qua1 = a.cell.item.quality
	local qua2 = b.cell.item.quality
	if isMax1==false and isMax2==true then return true end
	if isMax1==true and isMax2==false then return false end
	if sec1>sec2 and sec1>0 then return true end
	if sec2>sec1 and sec2>0 then return false end
	if qua1>qua2 and qua1~=qua2 and a.count>0 and isMax1==false then return true end
	if qua2>qua1 and qua1~=qua2 and b.count>0 and isMax2==false then return false end
	if a.count>b.count and a.count>0 and isMax1==false then return true end
	if b.count>a.count and b.count>0 and isMax2==false then return false end
	if isActive1==true and isActive2==false then return true end
	if isActive1==false and isActive2==true then return false end
	if cfg1.id > cfg2.id then return true else return false end
end

--设置人物名字/等级
function My:InitLab()
	if self.nameLab and self.lvLab then
		self.lvLab.text = UserMgr:GetGodLv()
		self.nameLab.text = User.instance.MapData.Name
	end
end

--初始化模块
function My:InitModuel()
	self.pop = ObjPool.Get(UIElixirPop)
	self.pop:Init(self.popTran)
end

--点击永久总览
function My:OnBtn1()
	self:UpShowProPop(0)
end

--点击限时总览
function My:OnBtn2()
	self:UpShowProPop(1)
end

--更新属性弹窗
function My:UpShowProPop(type)
	if self.proPop == nil then
		self.proPop = ObjPool.Get(UIElixirProPop)
		self.proPop:Init(self.proPopTran)
	end
	self.proPop:UpShow(true, type)
end

--初始化自身模型
function My:CreateModel()
    self.model1 = ObjPool.Get(RoleSkin)
	self.model1.eLoadModelCB:Add(self.SetPos1, self)
    -- self.model1:CreateSelf(self.modelTran)
	self.modelBox:AddComponent(typeof(UIRotateMod))
end

--设置自身模型位置
function My:SetPos1(go)
    
end

--
function My:RfRoleMod()
	TransTool.ClearChildren(self.modelTran.transform)
	self.model1:CreateSelf(self.modelTran)
end

--打开
function My:Open()
	self.go.gameObject:SetActive(true)
	self:SetLnsr("Add")
	self:UpItemData()
	if self.model1 then 
		-- self.model1:Clear() 
		self.model1:CreateSelf(self.modelTran)
	end
	self:UpSort()
	if self.selectId then
		local key = tostring(self.selectId)
		if self.itDic[key] then self.curIt = self.itDic[key] end
	end
	self:UpSelectData()
end

--关闭
function My:Close()
	if self.go then
		self.model1:Clear();
		self.go.gameObject:SetActive(false)
		self:UpCurMarkState(self.curIt, false)
	end
end

--卸载自身模型
function My:UnloadModel()
    if self.model1 then
        self.model1.eLoadModelCB:Remove(self.SetPos1, self)
        ObjPool.Add(self.model1)
        self.model1 = nil
    end
end

--清理缓存
function My:Dispose()
	self.curIt = nil
	self.selectId = nil
	self:SetLnsr("Remove")
end
    
--释放资源
function My:Clear()
	TableTool.ClearDicToPool(self.itDic)
	ObjPool.Add(self.pop)
	self.pop = nil
	ObjPool.Add(self.proPop)
	self.proPop = nil
	self:UnloadModel()
	TableTool.ClearUserData(self)
end

return My