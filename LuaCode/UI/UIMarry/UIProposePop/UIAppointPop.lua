--[[
 	authors 	:Liu
 	date    	:2018-12-15 11:05:00
 	descrition 	:预约婚礼弹窗
--]]

UIAppointPop = Super:New{Name = "UIAppointPop"}

local My = UIAppointPop

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    -- self.tex1 = CG(UITexture, root, "texBg1/icon")
    -- self.tex2 = CG(UITexture, root, "texBg2/icon")
    self.name1 = CG(UILabel, root, "bg/texBg1/lab")
    self.name2 = CG(UILabel, root, "bg/texBg2/lab")
    self.grid = Find(root, "bg/awardBg/item", des)
    self.go = root.gameObject
    self.cellList = {}

    SetB(root, "bg/btn", des, self.OnInvite, self)
    SetB(root, "bg/close", des, self.OnClose, self)
    self:InitData()
    -- self:InitIcon()
    self:InitCell()
    self:InitNameLab()
end

--初始化名字
function My:InitNameLab()
    local data = self.data
    if data then
        local str1 = ""
        local str2 = ""
          if User.MapData.Sex == 0 then
            str1 = data.name
            str2 = User.MapData.Name
          else
            str1 = User.MapData.Name
            str2 = data.name
          end
          self.name1.text = str1
          self.name2.text = str2
    end
end

--点击邀请
function My:OnInvite()
    UIProposePop:SetMenuState(4)
end

--初始化Cell
function My:InitCell()
    local cfg = GlobalTemp["61"]
    if cfg then
        for i,v in ipairs(cfg.Value1) do
            local it = ObjPool.Get(UIItemCell)
            it:InitLoadPool(self.grid, 0.8)
            it:UpData(v.id, v.value)
            table.insert(self.cellList, it)
        end
    end
end

--初始化头像
-- function My:InitIcon()
--     self.texName1 = string.format( "tx_0%s.png", User.MapData.Category)
--     AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon1, self))
--     if self.data then
--         self.texName2 = string.format( "tx_0%s.png", self.data.category)
--         AssetMgr:Load(self.texName2, ObjHandler(self.SetIcon2, self))  
--     end
-- end

--设置角色头像
-- function My:SetIcon1(tex)
--     self.tex1.mainTexture = tex
-- end

-- --设置仙侣头像
-- function My:SetIcon2(tex)
--     self.tex2.mainTexture = tex
-- end

--初始化仙侣数据
function My:InitData()
    local data = MarryInfo.data.coupleInfo
    self.data = data
end

--点击关闭
function My:OnClose()
    UIProposePop:Close()
end

--清理缓存
function My:Clear()
    -- AssetMgr:Unload(self.texName1,false)
    -- self.texName1 = nil
    -- if self.texName2 then
    --     AssetMgr:Unload(self.texName2,false)
    --     self.texName2 = nil
    -- end
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My