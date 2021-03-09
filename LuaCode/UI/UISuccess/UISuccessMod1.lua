--[[
 	authors 	:Liu
 	date    	:2018-8-31 11:29:29
 	descrition 	:成就界面模块1
--]]

UISuccessMod1 = Super:New{Name = "UISuccessMod1"}

local My = UISuccessMod1

function My:Init(root)
	local des, CG = self.Name, ComTool.Get

	self.go = root.gameObject
	self.progList = {}
	self.progLabList = {}

	self:InitProgList(root, CG)
end

--初始化进度条列表
function My:InitProgList(root, CG)
	for i=1, 7 do
		local prog = CG(UISlider, root, "succ"..i.."/progress")
		local lab = CG(UILabel, root, "succ"..i.."/progress/lab")
		table.insert(self.progList, prog)
		table.insert(self.progLabList, lab)
	end
end

--初始化所有进度条
function My:UpData()
	local info = SuccessInfo
	for i=1, 7 do
		local score = info:GetProgVal(i)
		local total = info:GetSuccScore(i)
		self.progList[i].value = score / total
		self.progLabList[i].text = score.." / "..total
	end
end

--清理缓存
function My:Clear()
	self.go = nil
end

-- 释放资源
function My:Dispose()
	self:Clear()
	TableTool.ClearDic(self.progList)
	TableTool.ClearDic(self.progLabList)
end

return My