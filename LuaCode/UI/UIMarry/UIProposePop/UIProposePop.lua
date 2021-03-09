--[[
 	authors 	:Liu
 	date    	:2018-12-8 16:15:00
 	descrition 	:提亲弹窗
--]]

UIProposePop = UIBase:New{Name = "UIProposePop"}

local My = UIProposePop

local strs = "UI/UIMarry/UIProposePop/"
require(strs.."UIMarrySuccPop")
require(strs.."UIAppointPop")
require(strs.."UIInvitePop")
require(strs.."UIFeastInfoPop")
require(strs.."UIInviteMgrPop")
require(strs.."UIMarryDes")
require(strs.."UIInvitePlusPop")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick

    self.moduel1 = Find(root, "moduel1", des)
    self.moduel2 = Find(root, "moduel2", des)
    self.moduel3 = Find(root, "moduel3", des)
    self.moduel4 = Find(root, "moduel4", des)
    self.moduel5 = Find(root, "moduel5", des)
    self.moduel6 = Find(root, "moduel6", des)
    self.moduel7 = Find(root, "moduel7", des)
    self.popPanel = Find(root, "PopPanel", des)
    self.grid = Find(root, "moduel1/bg/award1/Grid", des)

    self.name1 = CG(UILabel, root, "moduel1/bg/texBg1/lab")
    self.name2 = CG(UILabel, root, "moduel1/bg/texBg2/lab")
    self.timeLab = CG(UILabel, root, "moduel1/bg/time")
    self.tex = CG(UITexture, root, "moduel1/bg/award2/tex")
    
    self.modList = {}
    self.modGoList = {}
    self.cellList = {}
    
    SetB(root, "moduel1/bg/btn1", des, self.OnReject, self)
    SetB(root, "moduel1/bg/btn2", des, self.OnAgree, self)
    SetB(root, "moduel1/bg/close", des, self.Close, self)
    self:SetLnsr("Add")
    self:InitData()
    table.insert(self.modGoList, self.moduel1.gameObject)
    self:InitModule(self.moduel2, UIMarrySuccPop)
    self:InitModule(self.moduel3, UIAppointPop)
    self:InitModule(self.moduel4, UIInvitePop)
    self:InitModule(self.moduel5, UIFeastInfoPop)
    self:InitModule(self.moduel6, UIInviteMgrPop)
    self:InitModule(self.moduel7, UIMarryDes)
    self:InitTab()
    self:InitNameLab()
    self:InitAwardIt()
    self:InitTitle()
    self:InitPopModule()
end

--设置监听
function My:SetLnsr(func)
    MarryMgr.eUpTimer[func](MarryMgr.eUpTimer, self.RespUpTimer, self)
    MarryMgr.eEndTimer[func](MarryMgr.eEndTimer, self.RespEndTimer, self)
end

--响应更新倒计时 恭喜你们结缘成功！
function My:RespUpTimer(time)
    self.timeLab.text = "答复倒计时："..time
end

--响应结束倒计时
function My:RespEndTimer()
    self:Close()
end

--初始化奖励项
function My:InitAwardIt()
    if self.data then
        local type = self.data.type
        local cfg = ProposeCfg[type]
        if cfg == nil then return end
        for i,v in ipairs(cfg.award) do
            local it = ObjPool.Get(UIItemCell)
            it:InitLoadPool(self.grid, 0.8)
            it:UpData(v.k, v.v)
            table.insert(self.cellList, it)
        end
    end
end

--初始化称号
function My:InitTitle()
    if self.data then
        local type = self.data.type
        local cfg = ProposeCfg[type]
        if cfg == nil then return end
        self:InitTex(cfg.titleId)
    end
end

--初始化贴图
function My:InitTex(tId)
    local key = tostring(tId)
    local info = TitleCfg[key]
    if info == nil then return end
    
    self.texName1 = string.sub(info.prefab1,1,-5)..".png"
    AssetMgr:Load(self.texName1, ObjHandler(self.SetIcon1, self))
end

--设置角色头像
function My:SetIcon1(tex)
    if self.tex then
        self.tex.mainTexture = tex
    end
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

--点击拒绝
function My:OnReject()
    if self.data then
        MarryMgr:ReqProposeReply(self.data.id, 2)
    end
end

--点击同意
function My:OnAgree()
    if self.data then
        MarryMgr:ReqProposeReply(self.data.id, 1)
    end
end

--初始化数据
function My:InitData()
    local list = MarryInfo.pDataList
    if #list > 0 then
        self.data = list[1]
        return
    end
    self.data = nil
end

--初始化模块
function My:InitModule(module, class)
    local mod = ObjPool.Get(class)
    mod:Init(module)
    table.insert(self.modGoList, mod.go)
    table.insert(self.modList, mod)
end

--初始化弹窗模块
function My:InitPopModule()
    self.pop = ObjPool.Get(UIInvitePlusPop)
    self.pop:Init(self.popPanel)
end

--显示弹窗界面
function My:ShowPopMenu()
    self.pop:UpShow(true)
end

--打开分页
function My:OpenTab(index, isBack)
    self:ClearState()
    if isBack then self.isBack = isBack end
    self.index = index
    UIMgr.Open(UIProposePop.Name)
end

--初始化分页
function My:InitTab()
    local index = self.index
    if index then
        self:SetMenuState(index)
    else
        self:SetMenuState(1)
    end
end

--设置面板状态
function My:SetMenuState(index)
    for i,v in ipairs(self.modGoList) do
        if i == index then
            v:SetActive(true)
        else
            v:SetActive(false)
        end
    end
end

--重置状态
function My:ResetState()
    if self.isBack then
        UIMarryInfo:OpenTab(1)
    end
    self:ClearState()
end

--清理状态
function My:ClearState()
    self.isBack = nil
end

--清理缓存
function My:Clear()
    self.data = nil
    self.index = nil
    AssetMgr:Unload(self.texName1,false)
    self.texName1 = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearDicToPool(self.modList)
    self.modList = nil
    ObjPool.Add(self.pop)
    self.pop = nil
    self:SetLnsr("Remove")
end

return My