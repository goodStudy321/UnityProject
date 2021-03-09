--[[
 	authors 	:Liu
 	date    	:2018-12-20 09:35:00
 	descrition 	:结婚副本祝福
--]]

UIMarryCopyWish = Super:New{Name = "UIMarryCopyWish"}

local My = UIMarryCopyWish

local strs = "UI/UIMarry/UIMarryCopy/"
require(strs.."UIMarryWishBuyIt")
require(strs.."UIMarryWishLogIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.tog1 = CG(UIToggle, root, "texBg1")
    self.tog2 = CG(UIToggle, root, "texBg2")
    -- self.tex1 = CG(UITexture, root, "texBg1/icon")
    -- self.tex2 = CG(UITexture, root, "texBg2/icon")
    self.name1 = CG(UILabel, root, "texBg1/lab")
    self.name2 = CG(UILabel, root, "texBg2/lab")
    self.table = CG(UITable, root, "Scroll View/table")
    self.buyItem = FindC(root, "bg1/Scroll View/Grid/item", des)
    self.logItem = FindC(root, "Scroll View/table/item", des)

    self.panel1 = CGS(UIPanel, root, des)
    self.panel2 = CG(UIPanel, root, "bg1/Scroll View")
    self.panel3 = CG(UIPanel, root, "Scroll View")

    self.go = root.gameObject
    self.itList = {}
    self.logList = {}

    SetB(root, "bg1/btn", des, self.OnSure, self)
    SetB(root, "close", des, self.OnClose, self)

    self:InitData()
    -- self:InitIcon()
    -- self:InitLab()
    self:InitWishBugIt()
    self:InitWishLogIt()
    self:RefreshWishLog()
    self:InitNameLab()
    self:InitPanelDepth()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	MarryMgr.eWishLog[func](MarryMgr.eWishLog, self.RespWishLog, self)
end

--响应祝福日志
function My:RespWishLog()
    MarryInfo:RemoveWishLog()
    self:RefreshWishLog()
    self.table:Reposition()

end

--刷新祝福日志
function My:RefreshWishLog()
    local list = MarryInfo.mapData.wishInfoList
    local index = 0
    for i = #list, 1, -1 do
        index = index + 1
        self.logList[index]:UpShow(true)
        self.logList[index]:UpLab(list[i])
    end
end

--初始化祝福日志项
function My:InitWishLogIt()
    local info = MarryInfo
    local Add = TransTool.AddChild
    local list = info.mapData.wishInfoList
    local parent = self.logItem.transform.parent
    local len = info:GetWishMax()
    for i=1, len do
        local go = Instantiate(self.logItem)
        local tran = go.transform
        Add(parent, tran)
        local it = ObjPool.Get(UIMarryWishLogIt)
        it:Init(tran, v)
        table.insert(self.logList, it)
    end
end

--初始化祝福购买项
function My:InitWishBugIt()
    local Add = TransTool.AddChild
    local parent = self.buyItem.transform.parent
    for i,v in ipairs(MarryInfo.wishCfg) do
        local go = Instantiate(self.buyItem)
        local tran = go.transform
        go:SetActive(true)
        Add(parent, tran)
        local it = ObjPool.Get(UIMarryWishBuyIt)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
end

--初始化名字
function My:InitNameLab()
    if self.data1 and self.data2 then
        local str1 = ""
        local str2 = ""
          if self.data1.sex == 0 then
            str1 = self.data2.name
            str2 = self.data1.name
          else
            str1 = self.data1.name
            str2 = self.data2.name
          end
          self.name1.text = str1
          self.name2.text = str2
    end
end

--初始化头像 数量
-- function My:InitIcon()
--     if self.data1 and self.data2 then
--         self.texName1 = string.format( "tx_0%s.png", self.data1.category)
--         AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon1, self))
--         self.texName2 = string.format( "tx_0%s.png", self.data2.category)
--         AssetMgr:Load(self.texName2, ObjHandler(self.SetIcon2, self))
--     end
-- end

-- --设置角色头像
-- function My:SetIcon1(tex)
--     self.tex1.mainTexture = tex
-- end

-- --设置仙侣头像
-- function My:SetIcon2(tex)
--     self.tex2.mainTexture = tex
-- end

--初始化举报者名字
-- function My:InitLab()
--     if self.data1 and self.data2 then
--         self.name1.text = self.data1.name
--         self.name2.text = self.data2.name
--     end
-- end

--初始化数据
function My:InitData()
    local info = MarryInfo
    if info.feastData.feastState ~= 0 then
        local role1 = info.feastData.role1
        local role2 = info.feastData.role2
        if role1.sex == 0 then
            self.data1 = role2
            self.data2 = role1
        else
            self.data1 = role1
            self.data2 = role2
        end
	end
end

--获取当前人物选择
function My:GetRoleSelect()
    local state1 = self.tog1.value
    local state2 = self.tog2.value
    if not state1 and not state2 then
        return 0
    elseif state1 then
        return tonumber(self.data1.id)
    elseif state2 then
        return tonumber(self.data2.id)
    end
end

--获取当前选择的Tog
function My:GetTogSelect()
    for i,v in ipairs(self.itList) do
        if v.tog.value then
            return v.cfg
        end
    end
    return nil
end

--点击确定
function My:OnSure()
    local roleId = self:GetRoleSelect()
    local cfg = self:GetTogSelect()
    if roleId == 0 then
        UITip.Log("请先选择要赠送的角色")
        return
    end
    if tonumber(User.MapData.UIDStr) == roleId then
        UITip.Log("不能赠送给自己")
        return
    end
    if cfg == nil then
        UITip.Log("请先选择要赠送的礼物")
        return
    elseif cfg.type == 2 then
        local count = ItemTool.GetNum(cfg.val)
        if count < 1 then
            UITip.Log("您身上没有该道具")
            return
        end
    end
    MarryMgr:ReqWish(cfg.id, roleId)
end

--点击关闭
function My:OnClose()
    self:UpShow(false)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--初始化层级
function My:InitPanelDepth()
    self.panel1.depth = self.panel1.depth + 100
    self.panel2.depth = self.panel2.depth + 100
    self.panel3.depth = self.panel3.depth + 100
end

--清理缓存
function My:Clear()
    self.data1 = nil
    self.data2 = nil
    -- if self.texName1 then
	-- 	AssetMgr:Unload(self.texName1,false)
	-- 	self.texName1 = nil
	-- end
    -- if self.texName2 then
    --     AssetMgr:Unload(self.texName2,false)
    --     self.texName2 = nil
    -- end
end
	
--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearDicToPool(self.itList)
    TableTool.ClearDicToPool(self.logList)
    self:SetLnsr("Remove")
end
	
return My