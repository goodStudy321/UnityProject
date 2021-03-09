ExitBtn = UIBase:New{Name="ExitBtn"}
local My = ExitBtn
local isHide = true
function My:InitCustom()
    local TF = TransTool.Find
    self.ext=TF(self.root,"ExitBtn")
    self.cfg.cleanOp=0;
    self:lnsr("Add")
    local US = UITool.SetLsnrSelf
    US(self.ext,self.ExitC,self)
end

function My:lnsr( fun )
    EventMgr[fun]("BegChgScene",self.disChange);
    EventMgr[fun]("OnChangeScene",self.OnChangeScene);
    UIMainMenu.eHide[fun](UIMainMenu.eHide,self.RespBtnHide, self);
end
--响应展开按钮
function My:RespBtnHide(value)
    self.gbj:SetActive(value);
    isHide=value
end
--显示
function My:OnChangeScene()
    My.gbj:SetActive(isHide);
end
--释放与否控
function My.disChange( )
    My.active =1
    My.cfg.cleanOp=1;
    My.Close(My)
end
function My:OpenCustom()
    My.gbj:SetActive(isHide);
end
--点击退出
function My:ExitC(go)
    MsgBox.ShowYesNo("是否退出当前场景",self.YesCb,self,"确定",self.NoCb,self,"取消");
end
--点击MsgBox的确定按钮
function My:YesCb()
    -- self:Clear();
    SceneMgr:QuitScene();
end
--点击MsgBox的取消按钮
function My:NoCb()
    return ;
end
function My:CloseCustom(  )
    My.gbj:SetActive(false);
end
function My:DisposeCustom()
    My.cfg.cleanOp=1;
    self:lnsr("Remove")
    isHide = true
end
function My:Clear()
    isHide = true
end
return My
