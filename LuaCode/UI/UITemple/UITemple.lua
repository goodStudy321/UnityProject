UITemple=UIBase:New{Name="UITemple"}
local My = UITemple
local prv = {} --私有
local TRB = require("UI/UITemple/UITmpRwdBase")
local SHT = require("UI/UITemple/UIShutReward")
local STK = require("UI/UITemple/UIStreakReward")
local FOM = require("UI/UITemple/FmlOwnModel")
local SMB = require("UI/UITemple/UIShowMember")
local sti = require("UI/UITemple/RewardItem")
local mb = require("UI/UITemple/memberItem")

function My.OpenCheck()
    My.modelList=TempleMgr.GetModelInfo() 
    if My.modelList==nil or #My.modelList==0 then
        UITip.Log("主宰神殿尚未开启")
        else
        UIMgr.Open("UITemple")
    end
end
--初始化
function My:InitCustom()
    if self:Check() ==false then
       return
    end  
    local CG = ComTool.Get
    local TF = TransTool.Find
    local Tip = self.Name
    local Root =self.root 
    local TFC = TransTool.FindChild

    --道庭人物加载位置
    self.modelRoot=TF(Root,"OwnerModel",Tip)
    --遮挡
    self.barrier=TF(Root,"barrier",Tip).gameObject
    UITemple.barrier:SetActive(false)  
    self.TitleDic={"xm_01","xm_02","xm_03"}
--info目录
    local infoRoot = TF(Root,"info",Tip)
    local ULB = UILabel
    self.familyName=CG(ULB,infoRoot,"familyName",Tip)
    self.OwnerName=CG(ULB,infoRoot,"OwnerName",Tip)
    self.WinNum=CG(ULB,infoRoot,"WinNum",Tip)
    self.title=CG(UISprite,infoRoot,"title",Tip)
    self.tip=CG(ULB,infoRoot,"tip",tip)
--按钮
    local btnRoot = TF(Root,"btn",Tip)
    local UBTN = UIButton
    self.befor=CG(UBTN,btnRoot,"befor",Tip)
    self.next=CG(UBTN,btnRoot,"next",Tip)
    self.close=CG(UBTN,btnRoot,"close",Tip)
    self.winStreak=CG(UBTN,btnRoot,"winStreak",Tip)        
    self.winShut=CG(UBTN,btnRoot,"winShut",Tip)    
    self.getRwd=CG(UBTN,btnRoot,"getRwd",Tip)    
    self.showComp=CG(UBTN,btnRoot,"showComp",Tip)   
    self.drop=TFC(btnRoot,"getRwd/drop");
-- 奖励挂载点
    local rwdRoot = TF(Root,"rwd",Tip)
    local  UGD= UIGrid
    self.ownGrid=CG(UGD,rwdRoot,"ownGrid",Tip)
    self.memGrid=CG(UGD,rwdRoot,"memGrid",Tip)
--清空
    self.Glist={}
    --排行名次
    self.rank=self:startRankShow()
    self:AddEvent()
    
    
--加载3个版面
    local SHRoot = TF(Root,"UIShutReward",Tip)
    SHT:Init(SHRoot)
    local STRoot = TF(Root,"UIStreakReward",Tip)
    STK:Init(STRoot)
    local MBRoot = TF(Root,"UIShowMember",Tip)
    SMB:Init(MBRoot)
--改变
    prv.doChange(self.rank)

end                

function My.getModelList()
    return My.modelList
end
function My.getNowModel()
    return My.modelList[My.rank]
end
function prv.doChange(rank)
    My.rank=rank
    prv.SetMode(rank)
    prv.showInfo(rank)
    My:SetBtn()
    My:setShutState()
end

function My:startRankShow(  )
    for i=1,#My.modelList do
        if  UITmpRwdBase:isMyFamily(My.modelList[i].family_name) then
            return i;
        end
    end 
    return 1
end

function My:AddEvent()
	local E = UITool.SetBtnSelf
		E(self.befor, prv.goBefor)
		E(self.next, prv.goNext)
		E(self.close, self.Close,self)
		E(self.winStreak,prv.openWinStk)
		E(self.winShut, prv.openWinSht)
		E(self.getRwd, prv.getRwd)
		E(self.showComp,  prv.showComp)
    TempleMgr.eTempleStBtn:Add(self.SetBtn,self);
    TempleMgr.eBtnTrue:Add(self.SetBtn,self);
end

function My:SetBtn()
    local btn = self.getRwd.gameObject
    if TempleMgr.canSend==true then
        self.getRwd.enabled=true
        UITool.SetNormal(btn)
        self.drop:SetActive(true)        
        return;
    end
    local b = UITmpRwdBase:isMyFamily(self.templeInfo.family_name)
    local is_salary = TempleMgr.GetFmlInfo().is_salary
    if is_salary or not b or not TempleMgr.cansalara then
        self.getRwd.enabled=false
        self.drop:SetActive(false)
        UITool.SetGray(btn)
    else
        self.drop:SetActive(true)
        self.getRwd.enabled=true
        UITool.SetNormal(btn)
    end
end

function  My:setShutState( )
    local btn = self.winShut.gameObject
    if self.rank==1 then
        My.winShut.enabled=true
        UITool.SetNormal(btn)
    else
        My.winShut.enabled=false
        UITool.SetGray(btn)
    end
end

--设置
function prv.SetMode(rank)
    local FmlOwner = My.modelList[rank]
    if FmlOwner==nil then return end
    FOM:Init(My.modelRoot,FmlOwner)
end

--两个改变方法
function  prv.goBefor()
    local rank = My.rank-1
    if rank<1 then
        rank=#My.modelList
    end
    prv.doChange(rank)
end
function prv.goNext(  )
    local rank = My.rank+1
    if rank>#My.modelList then
        rank=1
    end
    prv.doChange(rank)
end

function prv.showInfo(rank)
    My.templeInfo = My.modelList[rank]
    My.familyName.text=My.templeInfo.family_name
    My.OwnerName.text=My.templeInfo.name
    My.WinNum.text=My.templeInfo.cv_times.."次"
    My.title.spriteName =My.TitleDic[rank]
    My.tip.text=string.format( "神级赛区第%s名",rank )
    prv.showSalary(rank)
end
--显示奖励
function prv.showSalary(rank)
    sInfo=TempleSalary[rank]
    My:disCell()
    --盟主
    for i=1,#sInfo.icon do
        My:AddCell(My.ownGrid,sInfo.icon[i])
    end
    My.ownGrid:Reposition()
    --全员
    for i=1,#sInfo.salary do
        My:AddCell(My.memGrid,sInfo.salary[i].id,sInfo.salary[i].num)
    end
    My.memGrid:Reposition()
end
function My:AddCell(grid,id,num)
    local cell = ObjPool.Get(UIItemCell)
    cell:InitLoadPool(grid.transform,0.7)
    cell:UpData(id,num)
    table.insert(self.Glist, cell)
end
function My:disCell(  )
local len  = #self.Glist
  for i=len,1,-1 do
     local ds= self.Glist[i]
     ds:DestroyGo()
     ObjPool.Add(ds)
     self.Glist[i]=nil
  end
end

function prv.openWinStk(  )
    STK:open()
end

function prv.openWinSht(  )
    if My.rank ~=1 then
        return
    end   
    SHT:open()
end
--跳转信息版面
function prv.showComp(  )
    UIMgr.Open("UIFamilyWar")
    UIMgr.Close(My.Name)
end

function prv.getRwd( )
    TempleMgr.toSend()
end

--显示奖励的回调方法
function My:RewardCb(name)
    local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
    end
   
end

function My:Clear()
    GbjPool:Clear("bhfp");
    TempleMgr.eTempleStBtn:Remove(self.SetBtn,self);
    TempleMgr.eBtnTrue:Remove(self.SetBtn,self);
    self:disCell( )
    SHT:Clear()
    STK:Clear()
    SMB:Clear()
    FmlOwnModel:Clear()
end

return My