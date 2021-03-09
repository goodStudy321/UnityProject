UILoadBase = Super:New{Name = "UILoadBase"}

local My = UILoadBase

My.GbjRoot = nil
My.RobInfo = nil

--初始化
--GbjRoot:加载界面
--RobInfo：UIRobbery界面数据
function My:Init()
	
end

--打开
function My:Open(t1, t2, t3)

end

--更新
function My:Update()

end

--关闭
function My:CloseC()

end

--释放
function My:Dispose()

end
--self.gbj是transform类型
function My:InitGbj()
	self.gbj = self.GbjRoot
	self.robInfo = self.RobInfo
	local sort = UICfg["UIRobbery"].sort
	sort = sort + 1
	UITool.Sort(self.gbj, sort, 20)
	self:Init()
end

function My:OpenGbj(t1, t2, t3)
	self:Open(t1, t2, t3)
	self.gbj.gameObject:SetActive(true)
end

function My:UpdateGbj()
	self:Update()
end

function My:CloseGbj()
	self:CloseC()
	self.gbj.gameObject:SetActive(false)
end

function My:DisposeGbj()
	if(LuaTool.IsNull(self.gbj)) then return end
	-- self:Dispose()
	AssetMgr:Unload(self.Name, ".prefab", false)
	GameObject.DestroyImmediate(self.gbj.gameObject)
	TableTool.ClearUserData(self)
end