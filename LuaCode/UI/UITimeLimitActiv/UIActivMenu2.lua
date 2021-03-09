--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面2
--]]

UIActivMenu2 = Super:New{Name="UIActivMenu2"}

local My = UIActivMenu2

require("UI/UITimeLimitActiv/UIActivMenu2It")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str = "Module/ScrollView/Grid"
    
    self.itList = {}
    self.go = root.gameObject

    self.timeLab = CG(UILabel, root, "time")
    self.lab1 = CG(UILabel, root, "spr/lab")
    self.lab2 = CG(UILabel, root, "spr/lab1")
    self.tex = CG(UITexture, root, "Img")
    self.grid = CG(UIGrid, root, str)
    self.item = FindC(root, str.."/item", des)
    
    self:InitShow()
    self:InitAItem()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local it = UITimeLimitActiv
    it.eUpTimer[func](it.eUpTimer, self.RespUpTimer, self)
end

--响应更新计时器
function My:RespUpTimer(remain)
    self.timeLab.text = string.format("[E5B45FFF]活动倒计时:[FFE9BDFF]%s", remain)
end

--初始化奖励项
function My:InitAItem()
    local Add = TransTool.AddChild
    local info = TimeLimitActivInfo
    local list = info:GetCfgList(TimeLimitFightCfg)
    for i,v in ipairs(list) do
        local item = Instantiate(self.item)
        local tran = item.transform
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(UIActivMenu2It)
        it:Init(tran, v, self.lab2.text)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self:UpBtns()
end

--更新按钮
function My:UpBtns()
    local info = TimeLimitActivInfo
    local dic = info:GetBtnState(2)
    for i,v in ipairs(self.itList) do
        local key = tostring(v.cfg.id)
        local state = (dic) and dic[key] or nil
        v:UpBtnState(state)
    end
    self.grid:Reposition()
end

--初始化显示
function My:InitShow()
    local str1 = ""
    local str2 = ""
    self.texName = ""
    local info = TimeLimitActivInfo
    local idList = info.idList
    local type = info:GetOpenType()
    if type == idList[1] then
        str1 = "法宝战力："
        str2 = User.MapData:GetFightValue(9)
        self.texName = "CB_AD2.png"
    elseif type == idList[2] then
        str1 = "翅膀战力："
        str2 = User.MapData:GetFightValue(12)
        self.texName = "CB_AD1.png"
    elseif type == idList[3] then
        str1 = "图鉴战力："
        str2 = User.MapData:GetFightValue(35)
        self.texName = "CB_AD3.png"
    end
    self.lab1.text = str1
    self.lab2.text = str2
    if StrTool.IsNullOrEmpty(self.texName) then return end
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName,false)
    ListTool.ClearToPool(self.itList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
end

return My