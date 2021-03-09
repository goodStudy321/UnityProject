require("UI/UITreaFever/AwardCell")
require("UI/UITreaFever/AwardItem")
require("UI/UITreaFever/FeverHelp")
require("UI/UITreaFever/FeverFindView")
require("UI/UITreaFever/FeverCircle")
TreaFever = Super:New{Name = "TreaFever"}
local My = TreaFever

local US = UITool.SetBtnClick
local USS = UITool.SetLsnrSelf
local T = TransTool.FindChild
local C = ComTool.Get
local CS = ComTool.GetSelf
local Add = TransTool.AddChild
My.items1 = {}
My.items2 = {}
My.items3 = {}
My.dic = {}
local itemObjs1 = {}
local itemObjs2 = {}
local itemObjs3 = {}
local feverCnt = 0 -- 自动计时
function My:Init(go)
    local TF = TransTool.Find
    self.go = go
    local trans = go.transform
    local des = self.Name
    US(trans, "oneBtn", des, self.OnOne, self)
    US(trans, "twoBtn", des, self.OnTwo, self)
    US(trans, "desBtn", des, self.OnDes, self)
    US(trans, "chooseBtn", des, self.OnChoose, self)
    self.chooseBtnSpr = C(UISprite,trans,"chooseBtn",des)
    self.chooseBtnRed=T(trans,"chooseBtn/red")
    self.timeLb = C(UILabel,trans,"time",des)
    self.twoBtnSpr = C(UISprite,trans,"twoBtn")
    self.twoBtnLb = C(UILabel,trans,"twoBtn/Label")
    self.lock = T(trans,"twoBtn/lock",des)
    self.action = T(trans,"twoBtn/action")
    self.eff = T(trans,"twoBtn/Effect")
    self.eff:SetActive(false)

    self.grid1 = C(UIGrid,trans,"choseGrid")
    self.grid2 = C(UIGrid,trans,"rareGrid")
    self.grid3 = C(UIGrid,trans,"bigGrid")
    self.cell1 = T(trans,"choseGrid/cell",des)
    self.cell2 = T(trans,"rareGrid/cell",des)
    self.cell3 = T(trans,"bigGrid/cell",des)
    self.cell1:SetActive(false)
    self.cell2:SetActive(false)
    self.cell3:SetActive(false)
    self.selOne = T(trans,"oneBtn/sel",des)
    self.selTwo = T(trans,"twoBtn/sel",des)
    local findRoot = TF(trans,"FeverFindView",des)
    FeverFindView:Init(findRoot)
    FeverHelp.curLayer=1
    self:InitActData()
    self:OnOne()
    self:ShowTime()
    self:UpTwoBtnState()
    self:SetLsner("Add")
end

function My:SetLsner(func)
    TreaFeverMgr.eChooseOrNo[func](TreaFeverMgr.eChooseOrNo, self.ShowCell, self)
    TreaFeverMgr.eBuyBack[func](TreaFeverMgr.eBuyBack, FeverHelp.BuyBack)
    TreaFeverMgr.eHideCell[func](TreaFeverMgr.eHideCell, self.HideChooseItem, self)
    TreaFeverMgr.eUpChooseBtn[func](TreaFeverMgr.eUpChooseBtn, self.UpChooseBtn, self)
    TreaFeverMgr.eUpTwoBtnEff[func](TreaFeverMgr.eUpTwoBtnEff, self.UpTwoBtnEff, self)
    -- PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end
--初始化活动数据
function My:InitActData()
    self.actData = FestivalActMgr:GetActInfo(FestivalActMgr.SMBZ)
end

function My:UpShow(value)
    self.go:SetActive(value)
end

function My:ShowData(index)
    self:ShowCell(index)
    FeverHelp.ShowData(index)
    self:UpChooseBtn(index)
end

function My:ShowCell(index)
    self:ShowChoose(index)
    self:ShowRareAward(index)
    self:ShowBigAward(index)
end

-- 确认选取按钮状态
function My:UpChooseBtn(index)
    local state = TreaFeverMgr:GetLayerStatus()
    state = state[index]
    local box = self.chooseBtnSpr.gameObject:GetComponent(typeof(BoxCollider))
    if state then
        self.chooseBtnSpr.spriteName = "btn_figure_down_avtivity"
        box.enabled = false
        self.chooseBtnRed:SetActive(false)
    else
        self.chooseBtnSpr.spriteName = "btn_figure_non_avtivity"
        box.enabled = true
        self.chooseBtnRed:SetActive(true)
    end
end

-- 宝藏二楼按钮状态
function My:UpTwoBtnState()
    local value = TreaFeverMgr:IsEnterTwo()
    local sprName = ""
    local col = ""
    if value then
        sprName = "sm_a03"
        col = "[FBC239]"
        UITool.SetNormal(self.twoBtnSpr.gameObject)
    else
        sprName = "sm_a04"
        col = "[FFFFFF]"
        UITool.SetGray(self.twoBtnSpr.gameObject,true)
    end
    self.twoBtnLb.text = col.."宝藏二层"
    self.twoBtnSpr.spriteName = sprName
    self.lock:SetActive(not value)
end

-- 宝藏二楼按钮特效
function My:UpTwoBtnEff(value)
    self.action:SetActive(value)
    self.eff:SetActive(value)

    if value then
        sprName = "sm_a03"
        col = "[FBC239]"
        UITool.SetNormal(self.twoBtnSpr.gameObject)
        self.twoBtnLb.text = col.."宝藏二层"
        self.twoBtnSpr.spriteName = sprName
        self.lock:SetActive(false)
    end
end

function My:ShowTime()
    local data = self.actData
	if not data then return end 
	local eDate = 0
	if data.eTime == 0 then
		eDate = data.eDate
	else
		eDate = data.eTime
	end
	local seconds = eDate - TimeTool.GetServerTimeNow()*0.001
	if not self.timer then
		self.timer = ObjPool.Get(DateTimer)
	end
	local timer = self.timer
	timer:Stop()
	if seconds <= 0 then
		self:CompleteCb()
	else
		timer.invlCb:Add(self.InvlCb, self)
    	timer.complete:Add(self.CompleteCb, self)
		timer.seconds = seconds
		timer.fmtOp = 0
        timer:Start()
        self:InvlCb()
	end
end

-- 间隔倒计时
function My:InvlCb()
	if self.timeLb then
		self.timeLb.text = self.timer.remain
	end
end

--结束倒计时
function My:CompleteCb()
	self.timeLab.text = "活动结束"
	FestivalActMgr.BlastState = false
	FestivalActMgr.eUpState(false)
end

function My:ShowChoose(index)
    self:ReNewItemNum(4,self.cell1,AwardCell,self.grid1,self.items1)
    local data = TreaFeverMgr:GetChoseAward()
    data = data[index]
    for i,v in ipairs(self.items1) do
        v:HideCell(false)
    end
    if not data or #data == 0 then
        return
    end
    local num = #data
    for i=1,num do
        self.items1[i]:InitItem(data[i],1)
    end
end

function My:HideChooseItem(id)
    self.items1[id]:HideCell(false)
end

function My:ShowRareAward(index)
    local data = TreaFeverMgr:GetRareAward()
    data = data[index]
    if not data or #data == 0 then return end
    local num = #data
    self:ReNewItemNum(num,self.cell2,AwardCell,self.grid2,self.items2)
    for i=1,num do
        self.items2[i]:InitItem(data[i],2)
    end
end

function My:ShowBigAward(index)
    local data = TreaFeverMgr:GetBigAward()
    data = data[index]
    if not data or #data == 0 then return end
    local num = #data
    self:ReNewItemNum(num,self.cell3,AwardCell,self.grid3,self.items3)
    for i=1,num do
        self.items3[i]:InitItem(data[i],2)
    end
end


function My:ReNewItemNum(num,obj,UIObj,grid,list)
	local len = #list
    for i=1,len do
        list[i]:Show(false)
    end
    if num <= len then
        for i=1,num do
            list[i]:Show(true)
		end
    else
        for i=1,len do
            list[i]:Show(true)
        end

		local needNum = num - len
        for i=1,needNum do
            self:CloneItem(obj,UIObj,grid,list)
        end
    end
    grid:Reposition()
end

function My:CloneItem(obj,UIObj,grid,list)
	local cloneObj = GameObject.Instantiate(obj)
	local parent = grid.gameObject.transform
	local AC = TransTool.AddChild
	local trans = cloneObj.transform
	local strans = obj.transform
	AC(parent,trans)
	trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
	trans.localScale = strans.localScale
	cloneObj:SetActive(true)

	local cell = ObjPool.Get(UIObj)
	cell:Init(cloneObj)

	list[#list + 1] = cell
end

-- 宝藏一层
function My:OnOne()
    FeverHelp.curLayer=1
    self.selOne:SetActive(true)
    self.selTwo:SetActive(false)
    self:ShowData(1)
end

-- 宝藏二层
function My:OnTwo()
    local isEner = TreaFeverMgr:IsEnterTwo()
    if not isEner then
        UITip.Log("抽中稀有奖池的奖励后才能进入第二层")
        return
    end
    FeverHelp.curLayer=2
    self:UpTwoBtnEff(false)
    self.selOne:SetActive(false)
    self.selTwo:SetActive(true)
    self:ShowData(2)
end

--描述按钮
function My:OnDes()
    local cfg = TreaFeverMgr:GetActDes()
    if cfg == nil then return end
    UIComTips:Show(cfg, Vector3.New(0, -170, 0))
end

function My:YesJumpCb()
    StoreMgr.OpenVIPStore()
end

function My:OnChoose()
    local list = TreaFeverMgr:GetChoseAward()
    list = list[FeverHelp.curLayer]
    if list == nil then UITip.Error("请选取奖励") return end
    if #list ~= 4 then UITip.Error("请选取奖励") return end
    local idList = {}
    for i,v in ipairs(list) do
        table.insert(idList,v.id)
    end
    self.idList=idList
    local desc = "确认选取后不可修改奖池内容，是否确认" 
    MsgBox.ShowYesNo(desc, self.YesChoose,self, "确定", self.NoChoose,self, "取消")
end
function My:YesChoose(  )
    TreaFeverMgr:ReqChoose(self.idList)
end
function My:NoChoose(  )
    return
end

function My:Clear()
    self.isOn = false
end

function My:Dispose()
    self:SetLsner("Remove")
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    if self.itimer then
        self.itimer:Stop()
        self.itimer:AutoToPool()
        self.itimer = nil
	end
    FeverHelp.Clear()
    TableTool.ClearDicToPool(self.items1)
    TableTool.ClearDicToPool(self.items2)
    TableTool.ClearDicToPool(self.items3)
    soonTool.ClearList(self.idList)
    FeverFindView:Clear()
    soonTool.DesGo("FeverFindItem")
    self.isOn = false
end

return My