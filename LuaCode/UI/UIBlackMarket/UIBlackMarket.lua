require("UI/UIBlackMarket/BlackHelp")
require("UI/UIBlackMarket/BlackShowItem")
require("UI/UIBlackMarket/BlackEffShow")
UIBlackMarket = UIBase:New{Name="UIBlackMarket"}
local My = UIBlackMarket
My.ItemLst={}
function My:InitCustom()
    --常用工具
    local tip = "UIBlackMarket"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self.ChoosePanel=TFC(root,"tf_ChoosePanel",tip)
    self.showless=CG(UISlider,root,"tf_ChoosePanel/sld_showless",tip)
    self.postf=TF(root,"tf_ChoosePanel/tf_postf",tip)
    self.BlackShowItem=TFC(root,"tf_ChoosePanel/tf_postf/tf_BlackShowItem_end",tip)
    --设置预制体
    soonTool.setPerfab(self.BlackShowItem,"BlackShowItem")

    self.overTime=CG(UILabel,root,"tf_ChoosePanel/lab_overTime",tip)
    self.timeDown=CG(UILabel,root,"tmbg/lab_timeDown",tip)
    self.redus=CG(UILabel,root,"lab_redus",tip)
    self.stratTip=TFC(root,"gbj_stratTip",tip)
    self.ShowGrid=CG(UIGrid,root,"gbj_stratTip/grid_ShowGrid",tip)
    self.dec=CG(UILabel,root,"gbj_stratTip/lab_dec",tip)
    UC(root,"uc_CloseBtn",tip,self.CloseClick,self)
    UC(root,"gbj_stratTip/uc_StartOPen",tip,self.StartOPenClick,self)
    self:lnsr("Add")
    BlackHelp.CreatItem( self.postf)	
end

function My:lnsr( fun )
    BlackMarketMgr.eLessChange[fun](BlackMarketMgr.eLessChange,self.SetLessLab,self)
    BlackMarketMgr.eItem[fun](BlackMarketMgr.eItem,self.StartChoose,self)
    BlackMarketMgr.ebackItem[fun](BlackMarketMgr.ebackItem,self.extracBack,self)
    PropMgr.eGetAdd[fun](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:OnAdd(action,dic)
    if action ==10433 then
        local lst = {}
        for i,v in ipairs(dic) do
            local KV = ObjPool.Get(KV)
            KV:Init(v.k,v.v)
            table.insert(lst, KV )
        end
        My.Showdic=lst
        BlackHelp.extracBack(  )
    end
end
function My:OpenCustom( )
    BlackHelp.OpenDo( )
    self:SetRwdShow(  )
    self:setLab()
    self:ChangeOpen( false )
end

function My:SetRwdShow(  )
    --local itemLst = GlobalTemp["188"].Value2
    local configNum = NewActivMgr:GetActivInfo(BlackHelp.ActiveId).configNum;
    local itemLst = tBlackAwardCfg[tostring(configNum)].awardList;
    soonTool.AddNoneCell(itemLst,self.ShowGrid,My.ItemLst,1)
end

function My:extracBack( )
    BlackHelp.choseBack()
    self:ChangeOpen( false )
end

function My:StartChoose(  )
    self:ChangeOpen( true)
    BlackHelp.StartChoose( )
end

function My:ChoseTime( num )
    self.showless.value=num/ BlackHelp.ChooseAllTime   
    self.overTime.text=num.."秒"
end

function My:setLab(  )
    local str = DesTemp["121"].desCN
    self.dec.text=str
    self:SetLessLab( )
end

function My:SetLessLab( )
    self.redus.text=BlackMarketMgr.lessTimes
end

function My:TimeLab( num )
    self.timeDown.text=num
end
--点击开始
function My:StartOPenClick(  )
    BlackHelp.StartClick() 
end

function My:CloseClick()
    self:Close()
end
--bl=true展示奖励false展示开始
function My:ChangeOpen( bl )
    self.stratTip:SetActive(not bl)
    self.ChoosePanel:SetActive(bl)
end

function My:Clear(isReconnect)
    if isReconnect then
        self:Close()
        return
    end
    self:lnsr("Remove")
    soonTool.desCell(My.ItemLst)
    BlackHelp.Clear()
end

return My
