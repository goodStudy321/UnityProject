--[[
 	authors 	:Liu
 	date    	:2018-11-1 11:55:00
 	descrition 	:仙魂系统界面
--]]

UIImmortalSoul = UIBase:New{Name = "UIImmortalSoul"}

local My = UIImmortalSoul

local strs = "UI/UIImmortalSoul/"
require(strs.."UIImmSoulWear")
require(strs.."UIImmSoulComp")
require(strs.."UIImmSoulDecomp")
require(strs.."UIImmSoulTip")
require(strs.."UIImmSoulLvPop")

function My:InitCustom()
	local root = self.root
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local FindC = TransTool.FindChild
	local SetB = UITool.SetBtnClick

	SetB(root, "bg/close", des, self.OnClose, self)
	self.bg = FindC(root, "bg", des)
	self.title = CG(UILabel, root, "bg/title")
	self.mod1Tran = Find(root, "Module1", des)
	self.mod2Tran = Find(root, "Module2", des)
	self.mod3Tran = Find(root, "Module3", des)
	self.tipTran = Find(root, "tipPanel", des)
	self.lvUpTran = Find(root, "popupPanel", des)
	self:InitModule1()
	self:InitModule3()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = ImmortalSoulMgr
	mgr.eEquip[func](mgr.eEquip, self.RespEquip, self)
	mgr.eUnload[func](mgr.eUnload, self.RespUnload, self)
	mgr.eLvUp[func](mgr.eLvUp, self.RespLvUp, self)
	mgr.eUpStone[func](mgr.eUpStone, self.RespUpStone, self)
	mgr.eUpDecompSet[func](mgr.eUpDecompSet, self.RespUpDecompSet, self)
	mgr.eDecomp[func](mgr.eDecomp, self.RespDecomp, self)
	mgr.eComp[func](mgr.eComp, self.RespComp, self)
	mgr.eAddSoul[func](mgr.eAddSoul, self.RespAddSoul, self)
end

--响应镶嵌仙魂
function My:RespEquip(index)
	self:OnEquip(index)
	self.mod1.wear:SetAction()
end

--响应卸下仙魂
function My:RespUnload(pos, index)
	self:OnUnload(pos, index)
	self.mod1.wear:SetAction()
end

--响应仙魂升级
function My:RespLvUp(pos, lvId)
	self.lvUp:UpLab()
	self.mod1.bag:UpLab()
	self.mod1.wear:UpPosIt(pos, lvId)
	self.mod1.wear:SetWearItLab(pos, lvId)
	self.mod1.wear:SetAction()
	ImmortalSoulInfo:UpUserList(pos, lvId)

	local nextCfg = self.lvUp:GetUpCfg()
	if nextCfg==nil then
		self.mod1.wear:UpAction(pos, false)
	end
end

--响应更新仙魂石
function My:RespUpStone()
	self.mod1.bag:UpLab()
end

--响应分解设置
function My:RespUpDecompSet()
	self.mod3:UpData()
end

--响应分解
function My:RespDecomp()
	self.mod3:UpData()
	self.mod1.bag:ResetBag()
	self.mod1.bag:UpLab()
	local info = ImmortalSoulInfo
	local str = string.format("分解成功，获得%s点仙尘", info.decompCount)
	UITip.Log(str)
	info:SetDecompCount(0)
	self.mod1.wear:SetAction()
end

--响应合成
function My:RespComp()
	self.mod2.compShow:UpData()
	self.mod2.compShow:CreatePrefab()
	self.mod1.bag:ResetBag()
	self.mod1.wear:ResetUseList()
	self.mod1.bag:UpLab()
	self.mod1.wear:SetAction()
	UITip.Log("合成成功")
end

--响应添加仙魂
function My:RespAddSoul()
	self.mod1.bag:AddIt()
end

--更新显示
function My:UpShow(num)
	if num == 1 then
		self:SetStae(true, true, false, false)
		self:UpTitle("仙魂佩戴")
	elseif num == 2 then
		if self.mod2 == nil then
			self:InitModule2()
		end
		self:SetStae(true, false, true, false)
		self:UpTitle("仙魂凝聚")
	elseif num == 3 then
		if self.mod3 == nil then
			self:InitModule3()
		end
		self:SetStae(false, false, false, true)
		self.mod3:UpData()
	end
end

--显示仙魂详情弹窗
function My:ShowTip(cfg, index, cellId)
	if self.tip == nil then
		self:InitTipMod()
	end
	self.tip:UpData(cfg, index, cellId)
end

--显示升级弹窗
function My:ShowLvUpPop(cfg, pos)
	if self.lvUp == nil then
		self:InitLvUpMod()
	end
	self.lvUp:UpData(cfg, pos)
end

--设置面板状态
function My:SetStae(state0, state1, state2, state3)
	self.bg:SetActive(state0)
	self.mod1Tran.gameObject:SetActive(state1)
	self.mod2Tran.gameObject:SetActive(state2)
	self.mod3Tran.gameObject:SetActive(state3)
end

--更新标题
function My:UpTitle(str)
	self.title.text = str
end

--初始化模块1
function My:InitModule1()
	self.mod1 = ObjPool.Get(UIImmSoulWear)
    self.mod1:Init(self.mod1Tran)
end

--初始化模块2
function My:InitModule2()
	self.mod2 = ObjPool.Get(UIImmSoulComp)
    self.mod2:Init(self.mod2Tran)
end

--初始化模块3
function My:InitModule3()
	self.mod3 = ObjPool.Get(UIImmSoulDecomp)
    self.mod3:Init(self.mod3Tran)
end

--初始化提示模块
function My:InitTipMod()
	self.tip = ObjPool.Get(UIImmSoulTip)
    self.tip:Init(self.tipTran)
end

--初始化升级模块
function My:InitLvUpMod()
	self.lvUp = ObjPool.Get(UIImmSoulLvPop)
    self.lvUp:Init(self.lvUpTran)
end

--点击关闭按钮
function My:OnClose()
	if self.mod1.go.activeSelf then
		self:Close()
	elseif self.mod2.go.activeSelf then
		self:UpShow(1)
		ObjPool.Add(self.mod2)
		self.mod2 = nil
	else
		self:UpShow(1)
	end
end

--获取合成数据
function My:GetCompData(togIndex, tabIndex)
	local info = ImmortalSoulInfo
	local list = info.compList[togIndex]
	if #list == 0 or list == nil then return end
	local id = nil
	local tabList = self.mod2.compList.itList[togIndex].itList
	if tabList == nil then return end
	for i,v in ipairs(tabList) do
		if v.index == tabIndex then
			id = v.cfg.id
			break
		end
	end
	if id == nil then return end
	local key = tostring(id)
	local compCfg = ImmSoulCompCfg[key]
	if compCfg == nil then return end
	return compCfg
end

--装备仙魂
function My:OnEquip(index)
	self.mod1.bag:RemoveIt(index)
	self.mod1.wear:AddIt()
	self.tip:UpShow(false)
end

--卸下仙魂
function My:OnUnload(pos)
	self.mod1.wear:RemoveIt(pos)
	self.mod1.bag:AddIt()
	self.tip:UpShow(false)
end

--获取孔的镶嵌位置
function My:GetPos()
	local pos = self.mod1.wear:GetMosaicPos()
	return pos
end

--获取核心位置
function My:GetCorePos()
	local pos = self.mod1.wear:GetCorePos()
	return pos
end

--打开分页(邮件专用)
function My:OpenTabByIdx(t1,t2,t3,t4)
	
end

--清理缓存
function My:Clear()
	ImmortalSoulInfo:ClearIndex()
end

--清空模块
function My:ClearMod()
	ObjPool.Add(self.mod1)
	self.mod1 = nil
	if self.mod2 then
		ObjPool.Add(self.mod2)
		self.mod2 = nil
	end
	if self.mod3 then
		ObjPool.Add(self.mod3)
		self.mod3 = nil
	end
	if self.tip then
		ObjPool.Add(self.tip)
		self.tip = nil
	end
	if self.lvUp then
		ObjPool.Add(self.lvUp)
		self.lvUp = nil
	end
end

--释放资源
function My:DisposeCustom()
	self:Clear()
	self:ClearMod()
	self:SetLnsr("Remove")
end

return My