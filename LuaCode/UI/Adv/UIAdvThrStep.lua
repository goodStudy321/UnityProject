--region UIPet.lua
--Date
--此文件由[HS]创建生成

UIAdvThrStep = Super:New{Name = "UIAdvThrStep"}

local M = UIAdvThrStep


function M:Init(root)
  	local trans = root
	self.go = root.gameObject
	local C = ComTool.Get
  	local T = TransTool.FindChild

	self.StepCurExp = C(UILabel, trans, "bless/curexp", name, false)
	self.StepLimitExp = C(UILabel, trans, "bless/limitexp", name, false)
	self.desLab = C(UILabel,trans,"bless/lab",name,false)

	--新的StepExpSlider
	self.StepExpSlider = C(UISprite,trans,"bless/rBg",name,false)
	--特效进度标签
	self.proSpFx = C(guiraffe.SubstanceOrb.OrbAnimator, trans, "bless/rBg/FX_SubstancePlane", name)
	self.proSpFx1 = T(trans, "bless/rBg/Fx_NengLiangQiu_UI02")

	self.starGbj = T(trans,"start")

	--新的星级
	self.CStepStarList = {}
	for i = 1,10 do
		local start = C(UISprite,trans,"start/start"..tostring(i),name,false)
		table.insert(self.CStepStarList,start)
	end
end

-- cur 当前值
--limit --当前等阶上限
function M:SetSlider(cur, limit)
	if not cur then cur = 0 end
	if not limit then limit = 0 end
	if cur == 0 and limit == 0 then
		if self.StepCurExp then self.StepCurExp.text = "0" end
		if self.StepLimitExp then self.StepLimitExp.text = "0" end
		if self.StepExpSlider then self.StepExpSlider.fillAmountValue = 0 end
		if self.proSpFx then self.proSpFx.FillRate = 0 end
		return
	end
	if self.StepCurExp then self.StepCurExp.text = tostring(cur) end
	if self.StepLimitExp then self.StepLimitExp.text = tostring(limit) end
	if self.StepExpSlider then self.StepExpSlider.fillAmountValue = cur / limit end
	if self.proSpFx then self.proSpFx.FillRate = cur / limit end
end

--新的星级显示
function M:SetNewStart(number,value)
	if not number then return end
	-- if value then
		for i,v in ipairs(self.CStepStarList) do
			v.spriteName = "star_dark"
		-- end
		for i = 1,number do
			local v = self.CStepStarList[i]
			v.spriteName = "star_light"
		end
	end
end

function M:SetActive(value)
  if not self.go then return end
  self.go:SetActive(value)
end

--设置星星是否显示
function M:SetStarActive(value)
	if not self.starGbj then return end
	self.starGbj:SetActive(value)
end

--设置经验条说明
function M:SetDesLab(str)
	self.desLab.text = str
end

function M:Open()
  self:SetActive(true)
end


function M:Close()
  self:Clear()
  self:SetActive(false)
end

function M:Clear()
--   local list = self.CStepList
--   if not list then return end
--   for i,v in ipairs(list) do
--     v.Yellow:SetActive(false)
--     v.Blue:SetActive(false)
--   end
end


function M:Dispose()
	-- if self.CStepList then
	-- 	local len = #self.CStepList
	-- 	while len > 0 do
	-- 		table.remove(self.CStepList,len)
	-- 		len = #self.CStepList
	-- 	end
	-- end
	-- self.CStepList = {}

	if self.CStepStarList then
		local startLen = #self.CStepStarList
		while startLen > 0 do
			table.remove(self.CStepStarList,startLen)
			startLen = #self.CStepStarList
		end
	end
	self.CStepStarList = {}
end

return M
