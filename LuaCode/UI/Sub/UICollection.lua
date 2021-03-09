--[[
	AU:Loong
	TM:2017.6.12
	BG:采集UI
--]]

local AssetMgr = Loong.Game.AssetMgr

UICollection = UIBase:New{Name = "UICollection"}

local My = UICollection

--采集中
My.eInCollect=Event();

function My:InitCustom()
	self:Reset()
	local des = self.Name
	local root = self.root
	local CG = ComTool.Get
	local bgTran = TransTool.Find(root,"bg",des)
	--前景精灵
	self.fg = CG(UISprite, bgTran, "sliderfg", des)
	--采集物图标
	local icon = CG(UISprite, bgTran, "icon", des)
	--标题
	self.title = CG(UILabel, bgTran, "title", des)
	--点击按钮碰撞
	self.btnBox = icon:GetComponent(typeof(BoxCollider))

	UITool.SetLsnrSelf(icon.gameObject, self.ReqBeg, self )

	self.icon = icon
	self:SetLsnr("Add")
end

--重置
function My:Reset()
	self.dur = 0
	self.cnt = 0
	self.pro = 0
end

--设置点击按钮碰撞盒激活状态
function My:SetBtnActive(at)
	if self.btnBox == nil then return end
	self.btnBox.enabled = at
end

--true:中断 前景设为红色 进度设为1
function My:SetInterupt(at)
	if (at) then
		self.fg.color = Color.New(1, 0, 0, 1)
		self.fg.fillAmount = 1
	else
		self.fg.color = Color.New(1, 1, 1, 1)
		self.fg.fillAmount = 0
	end
end


--请求开始采集
function My:ReqBeg()
	self:SetBtnActive(false)
	CollectMgr.ReqBeg()
end

--响应开始采集
function My:RespBeg(err, uid, dur)
	if err == 0 then
		self:SetInterupt(false)
		self.dur = dur
		self.cnt = 0
		self.pro = 0
	else
		self:Close()
	end
end

--响应结束采集
function My:RespEnd(err, uid)
	self:Close()
end

--响应中断采集
function My:RespStop(uid, err)
	self:SetInterupt(true)
end

function My:Update()
	if(CollectMgr.state == CollectState.Running) then
		self.cnt = self.cnt + Time.unscaledDeltaTime
		if self.cnt < self.dur then
			self.pro = self.cnt / self.dur
			self.eInCollect(self.cnt);
			self:TreasureCollec()
		else
			self:UnTreasureCollec()
			self.pro = 1
		end
		self.fg.fillAmount = self.pro
	end
end

--开始挖宝
function My:TreasureCollec()
	local collecState = TreasureMapMgr.isTreasureCollec
	if collecState == true then
		self.title.text = "挖宝"
	end
end

--结束挖宝
function My:UnTreasureCollec()
	local collecState = TreasureMapMgr.isTreasureCollec
	if collecState == true then
		self:Close()
		TreasureMapMgr:OnEndDig()
		local id = TreasureMapMgr.usePropId
		local uid = PropMgr.TypeIdById(id)
		PropMgr.ReqUse(uid, 1)
	end
end

function My:OpenCustom()
	if(CollectMgr.cfg ~= nil) then
		local cfg = CollectMgr.cfg
		self.icon.spriteName = cfg.icon
		self.title.text = cfg.text
	end
	self:SetBtnActive(true)
	self:SetInterupt(false)
	self.dur = CollectMgr.dur
	self.cnt = 0
end

--设置事件
function My:SetLsnr(fn)
	local CM = CollectMgr
	CM.eRespBeg[fn](CM.eRespBeg, self.RespBeg, self)
	CM.eRespEnd[fn](CM.eRespEnd, self.RespEnd, self)
	CM.einterupt[fn](CM.einterupt, self.RespStop, self)
end

function My:DiposeCustom()
	self:SetLsnr("Remove")
end

function My:CanRecords()
	do return false end
end

function My:ConDisplay()
	do return true end
end

return My
