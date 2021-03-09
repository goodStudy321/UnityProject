
InnateItem=Super:New{Name="InnateItem"}
local My=InnateItem

function My:Init( root,pos,grp )
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local CG = ComTool.Get;
    self.root=root
    self.go = root.gameObject;
    self.grp=grp;
    self.eff=TFC(root,"eff");
    self.eff:SetActive(false);
    self.lvUp=TFC(root,"lvUp");
    self.lvUp:SetActive(false);
    -- self.lvtxt=CG(UILabel,root,"lv")
    self.nametxt=CG(UILabel,root,"name")
    self.icon=CG(UITexture,root,"icon")
    self.red=TFC(root,"red")
    self.lock=TFC(root,"lock")
    self.red:SetActive(false);
    self.lock:SetActive(false);
    -- 设置位置
    root.parent=pos;
    root.localPosition = Vector3.zero
    --点击
    UITool.SetLsnrSelf(pos,self.onCick,self)
    --技能图片
    self.IconTex = nil
    --错误信息
    self.Error=""
end

function My:setLock(info )
    -- if InnateMgr.unlock(info) then
    --     UITool.SetNormal(self.icon)
    -- else
    --     UITool.SetGray(self.icon);
    -- end
    local bllock = false
        if info==nil then
            return;
        end
    if info.rad == false  then
        if info.lv==0 then
            if info.Error=="等级不足" or info.Error=="需要解锁前置天赋" or info.Error=="需要解锁此天赋" or info.Error=="天赋点投入不足" then
                bllock=true
            end
        end
        self.red:SetActive(false);
    else
    end
    self.red:SetActive(info.rad );
    self.lock:SetActive(bllock);
end

function My:upateInfo( info )
    self.info=info
    if  self.IconTex~=nil then
        AssetMgr:Unload(self.IconTex,false);
    end
    local slt =  SkillLvTemp[info.skillId]
    --技能图片
    self.IconTex =slt.icon;
    -- 加载icon
     AssetMgr:Load(self.IconTex,ObjHandler(self.LoadIcon,self));
    --等级上限制
    self.max=info.max
    --技能id
    self.skillid=info.skillId;
    --等级
    self.lv=info.lv;
    local lvText ="("..info.lv.."/"..info.max..")"
    --名字
    self.nametxt.text=slt.name..lvText
    info.changError=info.Error
    -- self:setLock(info);
end

function My:treeFalseRed()
    self.red:SetActive(false);
    self.info.changError="当前页只能选择一个天赋"
    self.lock:SetActive(true);
end
-- function My:treeFalseRed()
--     if info.Error=="等级不足" or info.Error=="需要解锁前置天赋"  or info.Error=="天赋点投入不足" then
--         bllock=true
--     end
-- end
function My:lvSuc( )
    self.lvUp:SetActive(false);
    self.lvUp:SetActive(true);
end

--加载icon完成
function My:LoadIcon(obj)
	if self.icon == nil then
        AssetTool.UnloadTex(obj.name)
        self.IconTex=nil
        return;
    end
    self.icon.mainTexture=obj;    
end

function My:onCick( ) 
    if self.info==nil then
        return;
    end
    InnateSkillInfo:myActive(true)
    UIInnate:chooseSkill(self.info)
end

--选中状态
function My:Slct( b )
    self.eff:SetActive(b);
end


function My:Dispose( )
    if LuaTool.IsNull(self.go) then return end
    AssetMgr:Unload(self.IconTex,false);
    self.IconTex=nil
    soonTool.Add(self.go,"InnateItem")
    TableTool.ClearUserData(self);
end

