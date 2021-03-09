UIGdAward = Super:New{Name = "UIGdAward"}
local My = UIGdAward

function My:Init(root)
    local name = self.Name
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    self.go = root.gameObject
    self.grid=CG(UIGrid,root,"Grid",name);
    self.getRwd=CG(UIButton,root,"GetBtn",name);
    UC(root, "GetBtn", name, self.GetAward, self);
    UC(root, "ToWeb", name, self.toweb, self);
    self.Glist={};
    self:lsnr("Add");
    self.id=User.instance.GameChannelId;
    self:showRwd( )
    self:SetBtn()
end
function My:lsnr(fun)
    GdAwardMgr.eBtn[fun](GdAwardMgr.eBtn, self.SetBtn, self);
end

function My:showRwd( )
    local info = GdRwd[self.id];
    if info==nil or info.rwd==nil then
       iTrace.Error("soon","H 好评配置表没有找到此gameChannelId 数据  "..self.id)
       return
    end
    local lst = info.rwd;
    for i=1,#lst do
        self:AddCell(self.grid,lst[i].id,lst[i].num)
    end
end
function My:AddCell(grid,id,num)
    local cell = ObjPool.Get(UIItemCell)
    cell:InitLoadPool(grid.transform)
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

function My:toweb( )
    local url = GdRwd[self.id].url;
    UApp.OpenURL(url);
    GdAwardMgr:satnSend();
end
--获得奖励
function My:GetAward( )
    local stat = GdAwardMgr.canGet
    if stat==1 then
        GdAwardMgr:rwdSend();
    else
        UITip.Log("请先评论");
    end
end
function My:SetBtn()
    local stat = GdAwardMgr.canGet
    if stat==2 then
        self.getRwd.enabled=false
        UITool.SetGray(self.getRwd);
    end
    -- local Gdshow = stat<2 and true or false; 
    -- UILvAward:SetAction(2, Gdshow)
    -- self:UpAction();
    -- LvAwardMgr:UpRedDot();
end

-- --更新红点
-- function My:UpAction()
--     local Gdshow = GdAwardMgr.canGet<2 and true or false; 
--     UILvAward:SetAction(2, Gdshow)
-- end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

function My:Dispose( )
    self:disCell(  )
    self:lsnr("Remove");
    TableTool.ClearUserData(self);
end

return My;