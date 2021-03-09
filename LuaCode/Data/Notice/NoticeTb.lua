--[[
公告结构
--]]
NoticeTb=Super:New{Name="NoticeTb"}
local My=NoticeTb

function My:Ctor()
	self.id=nil
	self.textList={}
	self.propList={}
end

function My:Init(id,texts,goods)
	--公告id
	self.id=id

	--信件内容中的字符串
	for i,v in ipairs(texts) do
		self.textList[i]=texts[i]
	end

	for i,v in ipairs(goods) do
		local tb = PropMgr.ParseGood(goods[i])
		self.propList[i]=tb
	end
end

function My:Dispose()
	ListTool.Clear(self.textList)
	while(#self.textList>0)do
		local tb = self.textList[#self.textList]
		ObjPool.Add(tb)
		self.textList[#self.textList]=nil
	end
end