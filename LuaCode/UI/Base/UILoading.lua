--[[
	AU:Loong
	TM:2017.05.11
	BG:描述
--]]
require("Tool/WWWTool")

UILoading = UIBase:New{Name = "UILoading"}
local My = UILoading

My.pro = nil;

--信息标签
My.msg = nil

--消息标签
My.tip = nil

--进度条
My.slider = nil


function My:InitCustom()
	local name = self.Name
	local CG = ComTool.Get
	local root = self.root
	self.tip = CG(UILabel, root, "tip", name)
	self.msg = CG(UILabel, root, "msg", name)
	self.slider = CG(UISprite, root, "sliderFg", name)
	self.bg = CG(UITexture, root, "bg", name)
	self:SetProgress(0)
	self.fbName = LoadingBgCfg[1].name
	self.first = true
	self.tipIdx = math.random(1, #LoadingTipCfg)
	self.idx = 1
	self.tm = 0
	self:SetLsnr("Add")
end

function My:SetLsnr(fn)
	SceneMgr.eOpenScene[fn](SceneMgr.eOpenScene, self.OnOpenScene, self)
end

function My:SetBg(tex)
	if tex == nil then return end
	self.bg.mainTexture = tex
end

function My:OnOpenScene(sceneID)
	if (LoadingMgr:LoadOnScene(sceneID, self.LoadTexCb, self)) then
		self.tm = 0
	end
end


function My:SetFirstBg(tex)
	self:SetBg(tex)
	self.firstBg = tex
	LoadingMgr:Add(self.fbName, tex)
	LoadingMgr:SetFirst(self.fbName)
end

--设置提示
function My:SetTip(text)
	if LuaTool.IsNull(self.tip) then return end
	self.tip.text = text;
end

function My:SetTipByCfg()
	local max = #LoadingTipCfg
	if self.tipIdx > max then self.tipIdx = 1 end
	local cfg = LoadingTipCfg[self.tipIdx]
	local text = cfg and cfg.des or "加载资源中"
	self.tipIdx = self.tipIdx + 1
	self:SetMsg(text)
end

--设置信息
function My:SetMsg(text)
	if LuaTool.IsNull(self.msg) then return end
	self.msg.text = text
end

--设置进度
function My:SetProgress(value)
	--self.slider.value = value
	if LuaTool.IsNull(self.slider) then return end
	self.slider.fillAmount = value
end

function My:Update()
	self.tm = self.tm + Time.deltaTime
	if (self.tm > 8 ) then
		self.tm = 0
		--self:SetTex()
		self:SetByWeight()
		self:SetTipByCfg()
	end
end

function My:SetByWeight()
	LoadingMgr:LoadByWeight(self.LoadTexCb, self)
end

function My:SetTex()
	local sb = ObjPool.Get(StrBuffer)
	sb:Apd("loading_"):Apd(self.idx):Apd(".jpg")
	local texName = sb:ToStr()
	ObjPool.Add(sb)
	LoadingMgr:Load(texName, self.LoadTexCb, self)

end

function My:LoadTexCb(tex)
	if tex then self.bg.mainTexture = tex end
	--self:SetIdx()
end

function My:OpenCustom()
	-- if self.first == true then
	-- 	AssetMgr:Load(self.fbName, ObjHandler(self.SetFirstBg, self))
	-- 	self.first = false
	-- else
	-- 	local fb = LoadingMgr:GetFirst()
	-- 	self:SetBg(fb)
	-- end
	self:SetByWeight()
	self:SetTipByCfg()
	--self:SetIdx()
	self.tm = 0
end

function My:SetIdx()
	self.idx = self.idx + 1
	if(self.idx > #LoadingBgCfg) then
		self.idx = 1
	end
end

function My:CloseCustom()
	--LoadingMgr:ClearTex()
end

function My:CanRecords()
	do return false end
end

return My
