UIPayMul = UIBase:New{Name = "UIPayMul"}

local My = UIPayMul

require("UI/PayMul/PayDouble/UIPayDouble")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local CG=ComTool.Get
    self.Grid=CG(UIGrid,root,"ActivModule/Grid",des)
    self.modDic = {}
    self.togDic = {}
    self.actionDic = {}
    self.strDic = {}
    self.modInfoDic = {}
    self.curIndex = 0

    if PayDoubleMgr:IsOpen() then
        self.strDic["1"] = "首充倍送"
        local module1 = Find(root, "PayDouble", des)
        self:SetModInfo(module1, UIPayDouble, 1)
    end

    self.tog = FindC(root, "ActivModule/Grid/tog1", des)

    SetB(root, "CloseBtn", des, self.OnClose, self)

    self:SetLnsr("Add")

    local index = (self.index==nil) and 1 or self.index
    if self.index == nil then self:OpenTab(index) end
end

--设置监听
function My:SetLnsr(func)
    PayMulMgr.eUpAction[func](PayMulMgr.eUpAction, self.UpAction, self)
    -- PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
-- function My:OnAdd(action,dic)
-- 	if action==10016 or action==10017 or action==10018 or action==10019 then		
-- 		self.dic=dic
-- 		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
-- 	end
-- end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.dic)
	end
end

--更新红点
function My:UpAction()
    local dic = self.actionDic
    for k,v in pairs(PayMulMgr.actionDic) do
        local go = dic[k]
        if go then
            go:SetActive(v)
        end
	end
end

--初始化Togs
function My:InitTogs()
    if self.tog == nil then self:Close() return end
    local CG = ComTool.Get
    local CGS = ComTool.GetSelf
    local Add = TransTool.AddChild
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild
    local parent = self.tog.transform.parent
    for k,v in pairs(self.strDic) do
        local go = Instantiate(self.tog)
        local tran = go.transform
        go.name = k
        local red = FindC(tran, "Action", self.Name)
        local lab1 = CG(UILabel, tran, "Label")
        local lab2 = CG(UILabel, tran, "Label1")
        local tog = CGS(UIToggle, tran, self.Name)
        lab1.text = v
        lab2.text = v
        Add(parent, tran)
        SetS(tran, self.OnTog, self, self.Name)
        self.actionDic[k] = red
        self.togDic[k] = tog
    end
    local index = self.index
	local num = (index and self.togDic[index]) and index or "1"
	self.togDic[num].value = true
    self:SwitchMenu(num)
    self.tog:SetActive(false)
    self.Grid:Reposition()
end

--点击Tog
function My:OnTog(go)
    self:SwitchMenu(go.name)
end

--设置界面状态
function My:SwitchMenu(key)
    if self.curIndex == key then return end
    local k = tostring(key)
    if self.modDic[k] == nil then
        local info = self.modInfoDic[k]
        if info == nil then return end
        self:InitModule(info.tran, info.obj, info.key)
    end
    for k,v in pairs(self.modDic) do
        if k == key then
            v:UpShow(true)
        else
            v:UpShow(false)
        end
    end
    self.curIndex = key
end

--初始化模块
function My:InitModule(module, class, index)
    local key = tostring(index)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    self.modDic[key] = mod
end

--设置模块信息
function My:SetModInfo(tran, obj, key)
    local info = {}
    info.tran = tran
    info.obj = obj
    info.key = key
    self.modInfoDic[tostring(key)] = info
end

--1.首充倍送
function My:OpenTab(index)
    self.index = tostring(index)
    UIMgr.Open(UIPayMul.Name)
    self:InitTogs()
    self:UpAction()
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.index = tostring(t1)
    self:InitTogs()
    self:UpAction()
end

--关闭界面
function My:OnClose()
	self:Close()
	JumpMgr.eOpenJump()
end

--清理缓存
function My:Clear()
    self.index = nil
    self.dic = nil
    self.curIndex = 0
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.modDic)
    TableTool.ClearDic(self.modInfoDic)
end

return My