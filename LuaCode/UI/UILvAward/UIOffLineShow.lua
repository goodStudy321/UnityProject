UIOffLineShow = Super:New{Name="UIOffLineShow"}
local AssetMgr=Loong.Game.AssetMgr
local My = UIOffLineShow
local idlst = {31010, 31011}
function My:Init(go)
    --常用工具
    local tip = "UIOffLineShow"
    self.root =go;
    self.go = go.gameObject
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get

    self.time=CG(UILabel,root,"msgRoot/lab_time",tip)
    self.haveNum=CG(UILabel,root,"msgRoot/cell/lab_haveNum",tip)
    self.Add=CG(UIButton,root,"msgRoot/cell/btn_Add",tip)
    self.AddTime=CG(UIButton,root,"msgRoot/cell/btn_AddTime",tip)
    self.tex=CG(UITexture,root,"msgRoot/cell/tex",tip)
    self.grid=CG(UIGrid,root,"msgRoot/sv/Grid")
    self.red=TFC(root,"msgRoot/cell/btn_AddTime/red",tip)
    self.cellLst={}
    self.eIsred = EventHandler(self.Isred, self)
    self.isDispose=false
    AssetMgr.Instance:Load("36011.png",ObjHandler(self.LoadIcon,self))
    self:ChangeShow( )
    self:ClickEvent()
    self:cellShow( )
    self:lsnr("Add")
    self:Isred()
end

function My:LoadIcon(obj )
    if not self.isDispose then
        self.tex.mainTexture=obj
	else
		AssetTool.UnloadTex(obj.name)
	end
    self.isDispose=true
end

function My:Isred(  )
    local b = OffRwdMgr.GetOffTime()<12
    self.red:SetActive(b)
end
function My:lsnr( fun )
    EventMgr[fun]("OfflFTimeChange",self.eIsred)
    PropMgr.eUpdate[fun](PropMgr.eUpdate,self.ChangeShow,self)
end

function My:cellShow( )
    local lst = GlobalTemp["120"].Value2
    soonTool.AddNoneCell(lst,self.grid,self.cellLst)
end

function My:UpShow( bool )
    self.go:SetActive(bool)
    if  OffRwdMgr.firstUIOpen==true and bool then
        OffRwdMgr.firstUIOpen=false
        OffRwdMgr.isShowRed(  )
    end
end

function My:setTimeShow( )
    local time=OffRwdMgr.GetOffTime()	
    self.time.text= time.."小时"
end

function My:ChangeShow( )
    self:setTimeShow()
    self:GetIconNum();
end

function My:GetIconNum( )
    self.CellNum = 0
    for i=1,#idlst do
        self.CellNum =self.CellNum + PropMgr.TypeIdByNum(idlst[i])
    end
    self.haveNum.text = self.CellNum.."/1";
end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.Add, self.AddClick, self)   
   US(self.AddTime, self.AddClick, self)
end

function My:AddClick(go)
    OffRwdMgr.Addtime()
end

function My:Dispose()
    self:lsnr("Remove")
    AssetMgr.Instance:Unload("36011.png",false)
    self.isDispose=true
    soonTool.desCell(self.cellLst)
end

return My
