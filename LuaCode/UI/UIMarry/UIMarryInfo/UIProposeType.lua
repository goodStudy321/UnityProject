--[[
 	authors 	:Liu
 	date    	:2018-12-7 10:33:00
 	descrition 	:提亲类型面板
--]]

UIProposeType = Super:New{Name = "UIProposeType"}

local My = UIProposeType

local strs = "UI/UIMarry/UIMarryInfo/"
require(strs.."UIMarryFriendIt")
require(strs.."UIProposeTypeIt")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild
	local str = "friendList/Scroll View/Grid"

	local friendItem = FindC(root, str.."/item")
	self.friendList = FindC(root, "friendList", des)
	self.friendlyLab = CG(UILabel, root, "friendList/bg/lab1")
	self.friendlyLabDes = CG(UILabel, root, "friendList/bg/lab")
	self.friendlyLabDes.transform.localPosition = Vector3.New(6,121,0)
	self.coupleSpr = CG(UISprite, root, "headBg/icon")
	self.coupleName = CG(UILabel, root, "headBg/lab")
	self.friendGrid = CG(UIGrid, root, str)
	self.togList = {}
	self.itList = {}
	self.typeList = {}
	self.go = root.gameObject
	SetB(root, "btn", des, self.OnSure, self)
	SetB(root, "tipBtn", des, self.OnTip, self)
	SetB(root, "headBg", des, self.OnFList, self)
	SetB(root, "close", des, self.OnClose, self)
	SetB(root, "friendList/close", des, self.OnPopClose, self)
	-- SetB(root, "friendList/boxBg", des, self.OnPopClose, self)
	self:InitTogs(root)
	self:InitFriendList(friendItem)
	self:InitTypeIt(root, des)
	self:InitOtherInfo()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.ePopClick[func](MarryMgr.ePopClick, self.RespPopClick, self)
end

--响应弹窗点击
function My:RespPopClick(isAllShow)
    if not isAllShow and self.go.activeSelf then
        VIPMgr.OpenVIP(1)
    end
end

--初始化结婚类型
function My:InitTypeIt(root, des)
	local Find = TransTool.Find
	for i,v in ipairs(ProposeCfg) do
		local tran = Find(root, "type"..i, des)
		local it = ObjPool.Get(UIProposeTypeIt)
		it:Init(tran, v)
		table.insert(self.typeList, it)
	end
end

--点击确定
function My:OnSure()
	local select = self:GetSelect()
	local cfg = ProposeCfg[select]
	if cfg == nil then return end
	local info = MarryInfo.data.selectInfo
	if info == nil then
		UITip.Error("请先选择伴侣")
		return
	elseif not info.Online then
		UITip.Error("选择的伴侣必须在线")
		return
	-- elseif info.Friendly < cfg.friendly then
	-- 	UITip.Error("当前档次婚礼需要与好友亲密度达到："..cfg.friendly)
	-- 	return
	end
	if select == nil then UITip.Error("至少选择一个档次") return end
	local IsSucc = self:IsSucc(select)
	if IsSucc == nil then return end
	if not IsSucc then UIMgr.Open(UIMarryPop.Name, self.OpenPop, self) return end
	MarryMgr:ReqPropose(info.ID, select)
	self:OnClose()
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel("元宝不足，是否充值？")
    end
end

--判断是否成功购买
function My:IsSucc(select)
	local info = RoleAssets
	local cfg = ProposeCfg[select]
	if cfg == nil then
		UITip.Log("配置表为空")
		return nil
	end
	if cfg.goldType == 3 then
		if info.BindGold < cfg.goldCount then
			return false
		end
	elseif cfg.goldType == 2 then
		if info.Gold < cfg.goldCount then
			return false
		end
	end
	return true
end

--点击提示
function My:OnTip()
	local cfg = InvestDesCfg["1024"]
    if cfg == nil then return end
    UIComTips:Show(cfg.des, Vector3.New(-200, -148, 0), nil, nil, nil, nil, nil, "xn_ty_04B")
end

--点击好友列表
function My:OnFList()
	local data = MarryInfo.data.coupleInfo
	if data then
		UITip.Log("您已结婚，不能对其他人提亲")
		return
	end

	local select = self:GetSelect()
	local cfg = ProposeCfg[select]
	if cfg == nil then return end
	self.friendList:SetActive(true)
	for i,v in ipairs(self.itList) do
		v:UpShow(cfg.friendly)
	end
	self:RefreshData()
	-- self.friendlyLab.text = "当前档次婚礼需要与好友亲密度达到："..cfg.friendly
	self.friendlyLab.text = ""
end

--点击关闭
function My:OnClose()
	UIMarryInfo:SetMenuState(1)
end

--点击关闭好友列表
function My:OnPopClose()
	self.friendList:SetActive(false)
end

--获取选择的档次
function My:GetSelect()
	for i,v in ipairs(self.togList) do
		if v.value then
			return i
		end
	end
	return nil
end

--初始化Toggle
function My:InitTogs(root)
	local CG = ComTool.Get
	local SetS = UITool.SetBtnSelf
	for i=1, 3 do
		local tog = CG(UIToggle, root, "type"..i)
		table.insert(self.togList, tog)
		SetS(tog.transform, self.OnTog, self)
	end
end

--点击Tog
function My:OnTog()
	if self.friendList.activeSelf then
		self:OnFList()
	end
end

--初始化亲密好友
function My:InitFriendList(item)
    local Add = TransTool.AddChild
	local parent = item.transform.parent
    for i,v in ipairs(FriendMgr.FriendList) do
        if User.MapData.Sex ~= v.Sex then
            local go = Instantiate(item)
            local tran = go.transform
            Add(parent, tran)
            local it = ObjPool.Get(UIMarryFriendIt)
            it:Init(tran, v)
            table.insert(self.itList, it)
        end
    end
    item:SetActive(false)
end

--刷新好友数据
function My:RefreshData()
    for i,v in ipairs(self.itList) do
        if v.data.Online then
            v.go.name = 10000 + i
        else
            v.go.name = 11000 + i 
        end
    end
    self.friendGrid:Reposition()
end

--更新仙侣数据
function My:UpOtherInfo(name, sex)
	local go = self.coupleSpr.gameObject
	self.coupleName.text = name
	if sex == -1 then
		go:SetActive(false)
	else
		go:SetActive(true)
	end
	local str = (sex == 0) and "TX_01" or "TX_02"
	self.coupleSpr.spriteName = str
end

--初始化仙侣数据
function My:InitOtherInfo()
	local data = MarryInfo.data.coupleInfo
	if data then
		self:UpOtherInfo(data.name, data.sex)
		for i,v in ipairs(self.itList) do
			if v.data.ID == data.id then
				MarryInfo.data.selectInfo = v.data
				break
			end
		end
	else
		local sex = (User.MapData.Sex==0) and 1 or 0
		self:UpOtherInfo("请选择提亲对象", -1)
	end
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
	self:Clear()
	ListTool.ClearToPool(self.itList)
	ListTool.ClearToPool(self.typeList)
	MarryInfo:ClearSelectData()
	self:SetLnsr("Remove")
end

return My