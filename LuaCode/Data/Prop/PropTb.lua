--[[
道具结构 p_goods
]]

PropTb=Super:New{Name="PropTb"}
local My=PropTb

function My:Ctor()
	self.eDic={}
	self.bList={}
	self.lDic={}
end

function My:Init(good)
	--唯一id
	self.id=good.id

	--道具表id
	self.type_id=good.type_id

	--是否绑定
	self.bind=good.bind 

	--数量
	self.num=good.num

	--卓越属性
	TableTool.ClearDic(self.eDic)
	local eDic = good.excellent_list
	for i,p_kv in ipairs(eDic) do
		self.eDic[tostring(p_kv.id)]=p_kv.val
	end

	--翅膀
	local wing=good.wing
	self.wing_id=nil
	ListTool.Clear(self.bList)
	TableTool.ClearDic(self.lDic)

	if(wing~=nil)then
		--翅膀的id
		self.wing_id=wing.wing_id

		--翅膀的基础属性
		local bProp = wing.base_props
		for i,v in ipairs(bProp) do
			self.bList[#self.bList+1]=v
		end

		--翅膀的传奇属性
		local lProp = wing.legend_props
		for i,v in ipairs(lProp) do
			self.lDic[tostring(v.id)]=v.val
		end
	end
	
	self.startTime=good.start_time --开始生效的时间
	self.endTime=good.end_time  --now>endTime 过期
	self.market_end_time = good.market_end_time --可上架时间
end

--拷贝数据
function My:CopyTbData(newTb)
	newTb.id = self.id;
	newTb.type_id = self.type_id;
	newTb.bind = self.bind;
	newTb.num = self.num;
	--卓越属性
	TableTool.ClearDic(newTb.eDic)
	local eDic = self.eDic
	for k,v in ipairs(eDic) do
		newTb.eDic[k]=v
	end

	--翅膀
	ListTool.Clear(newTb.bList)
	TableTool.ClearDic(newTb.lDic)

	--翅膀的id
	newTb.wing_id=self.wing_id

	--翅膀的基础属性
	local bProp = self.bList
	for i,v in ipairs(bProp) do
		newTb.bList[#newTb.bList+1]=v
	end

	--翅膀的传奇属性
	local lProp = self.lDic
	for i,v in ipairs(lProp) do
		newTb.lDic[i]=v
	end

	newTb.startTime=self.startTime --开始生效的时间
	newTb.endTime=self.endTime  --now>endTime 过期
	newTb.gotTime = self.gotTime --得到的时间
end

function My:Dispose()
	--卓越属性
	TableTool.ClearDic(self.eDic)

	--翅膀的基础属性
	ListTool.Clear(self.bList)

	--翅膀的传奇属性
	TableTool.ClearDic(self.lDic)

	if self.isUp then self.isUp=nil end
	if self.isDown then self.isDown=nil end
end