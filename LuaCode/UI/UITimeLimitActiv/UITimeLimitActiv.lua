--[[
 	authors 	:Liu
 	date    	:2019-3-18 17:00:00
 	descrition 	:限时活动界面
--]]

UITimeLimitActiv = UIBase:New{Name = "UITimeLimitActiv"}

local My = UITimeLimitActiv

local strs = "UI/UITimeLimitActiv/"
require(strs.."UIActivMenu1")
require(strs.."UIActivMenu2")
require(strs.."UIActivMenu3")
require(strs.."UIActivMenu4")
require(strs.."UIActivMenu5")

My.eUpTimer = Event()

function My:InitCustom()
    local des = self.Name
	local root = self.root
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.modList = {}
	self.togList = {}
	self.actionList = {}
	self.btnItem = FindC(root, "ActivModule/Grid/item", des)

	local module1 = Find(root, "Menu1", des)
	local module2 = Find(root, "Menu2", des)
	local module3 = Find(root, "Menu3", des)
	local module4 = Find(root, "Menu4", des)
	local module5 = Find(root, "Menu5", des)
	self:InitModule(module1, UIActivMenu1)
	self:InitModule(module2, UIActivMenu2)
	self:InitModule(module3, UIActivMenu3)
	self:InitModule(module4, UIActivMenu4)
	self:InitModule(module5, UIActivMenu5)

	SetB(root, "Close", des, self.Close, self)

	--TimeLimitActivMgr:UpNorAction(1)

	self:InitTogs()
	self:UpAction()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = TimeLimitActivMgr
	mgr.eUpAward[func](mgr.eUpAward, self.UpAward, self)
	mgr.eEndActiv[func](mgr.eEndActiv, self.RespEndActiv, self)
	ActivStateMgr.eUpActivState[func](ActivStateMgr.eUpActivState, self.RespUpActivState, self)
	PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10365 or action==10368 then
		self.dic=dic
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应结束活动
function My:RespEndActiv(type)
	local curType=TimeLimitActivInfo:GetOpenType()
	if curType~=type then return end
	local info = TimeLimitActivInfo
	if info.isLastDayDic[tostring(type)] == 1 then
		self:Close()
	end
end

--更新奖励
function My:UpAward(id)
	local it1 = self.modList[1]
	it1.modList[1]:UpBtns()
	self.modList[2]:UpBtns()
	self.modList[3]:UpBtns(id)
	self.modList[4]:UpBtns()
	self.modList[5]:UpBtns()
	self:UpAction()
end

--响应更新活动状态
function My:RespUpActivState(id)
	local info = TimeLimitActivInfo
	for i,v in ipairs(info.idList) do
		if v == id then
			self:Close()
		end
	end
end

--初始化Tog
function My:InitTogs()
	local strList = self:GetBtnStr()
	if #strList < 1 then return end
	local CG = ComTool.Get
	local CGS = ComTool.GetSelf
	local Add = TransTool.AddChild
	local SetS = UITool.SetLsnrSelf
	local FindC = TransTool.FindChild
	local parent = self.btnItem.transform.parent
	for i=1, #strList do
		local go = Instantiate(self.btnItem)
		go:SetActive(true)
		go.name = i
		local tran = go.transform
		local red = FindC(tran, "redDot", self.Name)
		local lab1 = CG(UILabel, tran, "Label")
		local lab2 = CG(UILabel, tran, "Label1")
		local tog = CGS(UIToggle, tran, self.Name)
		lab1.text = strList[i]
		lab2.text = strList[i]
		Add(parent, tran)
		SetS(tran, self.OnTog, self, self.Name)
		table.insert(self.actionList, red)
		table.insert(self.togList, tog)
	end
	local index = self.index
	local num = (index) and index or 1
	self.togList[num].value = true
	self:SwitchMenu(num)
end

--点击按钮
function My:OnTog(go)
	self:SwitchMenu(tonumber(go.name))
end

--设置界面状态
function My:SwitchMenu(index)
    for i,v in ipairs(self.modList) do
        if i == index then
            v:UpShow(true)
        else
            v:UpShow(false)
        end
    end
end

--获取已开启的活动ID
function My:GetActivId()
	local id = 0
	local info = TimeLimitActivInfo
	for k,v in pairs(info.activDic) do
		id = tonumber(k)
		break
	end
	return id
end

--获取按钮文本
function My:GetBtnStr()
	self.strList = {}
	self.norList = {}
	local info = TimeLimitActivInfo
	local type = info:GetOpenType()
	local idList = info.idList
	if type == idList[1] then
		self.norList = {"法宝排行"}
		self.strList = {"法宝排行", "法宝战力", "法宝抢购", "法宝灵力", "累计充值"}
	elseif type == idList[2] then
		self.norList = {"翅膀排行"}
		self.strList = {"翅膀排行", "翅膀战力", "翅膀抢购", "翅膀灵力", "累计充值"}
	elseif type == idList[3] then
		self.norList = {"图鉴排行"}
		self.strList = {"图鉴排行", "图鉴战力", "图鉴抢购", "图鉴灵力", "累计充值"}
	end
	local val = (info.isLastDayDic[tostring(type)]==1) and self.norList or self.strList
	return val
end

--初始化模块
function My:InitModule(module, class)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    table.insert(self.modList, mod)
end

--更新红点
function My:UpAction()
	local list = self.actionList
	local dic = TimeLimitActivMgr:GetActionList()
	for i,v in ipairs(list) do
		v:SetActive(false)
	end
	for k,v in pairs(dic) do
		if v == 3 then
			if list[4] then
				list[4]:SetActive(true)
			end
		else
			if list[v] then
				list[v]:SetActive(true)
			end
		end
	end
end

--1.排名奖励
--2.战力奖励
--3.灵力奖励
--4.抢购次数
--5.累计充值
function My:OpenTab(index)
	self.index = index
    UIMgr.Open(UITimeLimitActiv.Name)
end

--清理缓存
function My:Clear()
	self.index = nil
end

--释放资源
function My:DisposeCustom()
	self:Clear()
	TableTool.ClearDicToPool(self.modList)
	self.modList = nil
	self.dic = nil
	self:SetLnsr("Remove")
end

return My