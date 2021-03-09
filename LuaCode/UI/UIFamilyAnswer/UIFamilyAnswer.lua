--[[
 	authors 	:Liu
 	date    	:2018-5-30 09:55:40
 	descrition 	:道庭答题界面
--]]

UIFamilyAnswer = UIBase:New{Name = "UIFamilyAnswer"}

local My = UIFamilyAnswer

local strs = "UI/UIFamilyAnswer/"
require(strs.."UIFamilyAnswerRank")
require(strs.."UIFamAnswerExitTip")

function My:InitCustom()
    local TF = TransTool.FindChild
    local CG,Find = ComTool.Get,TransTool.Find
    local root,des,str = self.root,self.Name,"rank/"
    local rankTran = Find(root, str.."rankBar", des)
    local exitTipTran = Find(root, "ExitTip", des)
    UITool.SetBtnClick(root, "exitBtn", des, self.OnExit, self)

    if ScreenMgr.orient == ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(root, "rank", des, true)
    end

    self.collId = 100035
    self.exitBtn = TF(root, "exitBtn", des)
    self.timerLab = CG(UILabel, root, str.."rTime/timer")
    self.expLab = CG(UILabel, root, str.."getedExp/expLab")
    self:InitSelf(rankTran, exitTipTran)
    FamilyAnswerMgr:isHideTimer(false)
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = FamilyAnswerMgr
    local cMgr = CollectMgr
    mgr.eGetExp[func](mgr.eGetExp, self.RespGetExp, self)
    mgr.eUpTimer[func](mgr.eUpTimer, self.RespUpTimer, self)
    mgr.eEndTimer[func](mgr.eEndTimer, self.RespEndTimer, self)
    mgr.eShowTip[func](mgr.eShowTip, self.RespShowTip, self)
    mgr.eIsCollection[func](mgr.eIsCollection, self.RespIsCollection, self)
    cMgr.eRespBeg[func](cMgr.eRespBeg, self.RespCollectStart, self)
    cMgr.eRespEnd[func](cMgr.eRespEnd, self.RespCollectEnd, self)
    UIMainMenu.eHide[func](UIMainMenu.eHide, self.RespBtnHide, self)
    ScreenMgr.eChange[func](ScreenMgr.eChange, self.ScrChg, self)
    NavPathMgr.eNavPathEnd[func](NavPathMgr.eNavPathEnd,self.NavPathEnd,self)
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "rank", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "rank", nil, true, true)
	end
end

--响应获取经验
function My:RespGetExp(exp)
    local num = math.floor(exp / 10000)
    local tmep = (exp>10000) and num.."万" or exp
    if self.expLab then
        self.expLab.text = tmep
    end
end

--响应更新倒计时
function My:RespUpTimer(time)
    if self.timerLab then
        self.timerLab.text = time
    end
end

--响应结束倒计时
function My:RespEndTimer()
    self.exitTip.go:SetActive(false)
end

--响应显示退出提示界面
function My:RespShowTip(time, state)
    local it = self.exitTip
    it.go:SetActive(state)
    it:UpTimeLab(time)
end

--响应寻路结束
function My:NavPathEnd(type, id)
    CollectMgr.ReqBeg()
end

--响应采集结束
function My:RespCollectEnd(err, uid)
	if (err>0) then
        UITip.Error(ErrorCodeMgr.GetError(err))
		return
    end
    FamilyAnswerInfo.coll = true
    CollectMgr:SetStop(true)
    UIMgr.Open(UIChat.Name, self.OpenChat,self)
end

--响应是否采集
function My:RespIsCollection(collection)
    if collection then return end
    local go = User.instance:GetNearestColl(self.collId, "")
    if go ~= nil then
        local pos = go.transform.position
        local changePos = MapHelper.instance:GetCanStandPos(pos, 1)
        local pPos = FindHelper.instance:GetOwnerPos()
        local dis = Vector3.Distance(pPos, changePos)
        if dis < 1 then
            CollectMgr.ReqBeg()
        else
            User:StartNavPath(changePos, 30007, -1, 0)
        end
    end
end

--响应采集开始（已经采集后才会触发）
function My:RespCollectStart(err, uid, dur)
    if (err>0) then
        UITip.Error(ErrorCodeMgr.GetError(err))
		return
    end
end

--响应隐藏退出按钮
function My:RespBtnHide(value)
    if self.exitBtn then
        self.exitBtn:SetActive(value)
    end
end

--聊天面板回调
function My:OpenChat(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:SwatchTg(2)
        ui:SetTween(true)
	end
end

--初始化自身
function My:InitSelf(tran1, tran2)
    self.timerLab.text = ""
    self.rank = ObjPool.Get(UIFamilyAnswerRank)
    self.rank:Init(tran1)
    self.exitTip = ObjPool.Get(UIFamAnswerExitTip)
    self.exitTip:Init(tran2)
end

--点击退出按钮
function My:OnExit()
    MsgBox.ShowYesNo("是否退出场景？", self.YesCb, self)
end

--点击确定按钮
function My:YesCb()
    SceneMgr:QuitScene()
    FamilyAnswerMgr:isHideTimer(true)
end

--重写UIBase方法，持续显示
function My:ConDisplay()
    do return true end
end

--清理缓存
function My:Clear()
    CollectMgr:SetStop(false)
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    ObjPool.Add(self.rank)
    self.rank = nil
    ObjPool.Add(self.exitTip)
    self.exitTip = nil
end

return My