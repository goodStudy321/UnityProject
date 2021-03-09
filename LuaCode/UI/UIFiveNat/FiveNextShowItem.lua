FiveNextShowItem = Super:New{Name="FiveNextShowItem"}
local My = FiveNextShowItem
function My:Init(go)

    self.root=go.transform
    self.go=go
    --常用工具
    local tip = "FiveNextShowItem"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self:ClickEvent()
    self.eff=TFC(root,"eff",tip)
    self.Icon=CG(UITexture,root,"Icon",tip)
end

function My:SetInfo( id,index )
    self.itemId=id
    self.Index=index
    self.haveThis = FiveElmtMgr.IndexInBook( id )
    self:UpdateEff( )
    self.IconTex = id..".png"
    AssetMgr:Load(self.IconTex,ObjHandler(self.LoadIcon,self));
    return   self.haveThis and 1 or 0
end


function My:UpdateEff(  )
   if  self.haveThis then
    temp = SMSProTemp[tostring( self.itemId)]
       if temp.quality == 1 then
           path = "FX_Five_white"
       elseif temp.quality == 2 then
           path = "FX_Five_blue"
       elseif temp.quality == 3 then
           path = "FX_Five_Violet"
       elseif temp.quality == 4 then
           path = "FX_Five_yellow"
       elseif temp.quality == 5 then
           path = "FX_Five_gules"
       elseif temp.quality == 6 then
           path = "FX_Five_Pink"
       end
       --特效优化后暂时用不到这个特效
    --path = string.format("FX_sky_00%s",temp.quality)
    if StrTool.IsNullOrEmpty(path) == true then return end
    if self.EffPath == path then return end
    self:UnloadMode()
    self.EffPath = path
    local del = ObjPool.Get(DelGbj);
	del:Add(self.eff);
    del:SetFunc(self.LoadEff,self);
    Loong.Game.AssetMgr.LoadPrefab(path,GbjHandler(del.Execute,del));
   end 
end

function My:LoadEff(go, parent)
    if  go.name ~= self.EffPath then 
        self:UnloadMode()
        return
    end
    self.Effect = go
    local trans = go.transform
    trans.parent = parent.transform
	trans.eulerAngles = Vector3.zero
    trans.localPosition = Vector3.zero
    trans.localScale = Vector3.one * 1
    --刘路的版本，改版特效优化后后先不清楚用不用的到，先注释
    --local wdg = go:GetComponentsInChildren(typeof(Transform), true);
    --local len = wdg.Length - 1
    --for i=0,len do
    --   wdg[i].localScale=Vector3.New(0.7,0.7,0.7)
    --end
    --trans.localScale =Vector3.New(0.7,0.7,0.7)
    local cs = go:AddComponent(typeof(UIEffBinding))
    local wg = ComTool.GetSelf(UIWidget, parent.transform,"soon五行")
    if cs and wg then
        cs.specifyWidget = wg
    end
    LayerTool.Set(trans, 5)
    go:SetActive(true)
end
function My:UnloadMode()
	if LuaTool.IsNull(self.Effect) == false then
		Destroy(self.Effect)
		if not StrTool.IsNullOrEmpty(self.EffPath) then
			AssetMgr:Unload(self.EffPath,".prefab", false)
		end
	end

	self.Effect = nil
	self.EffPath = nil
end
--加载icon完成
function My:LoadIcon(obj)
	if LuaTool.IsNull(self.Icon)  then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.Icon.mainTexture=obj;   
    table.insert( FiveCopyHelp.txtUload, obj.name ) 
end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.go, self.MyClick, self)
end

function My:MyClick(  )
    FiveCopyHelp.SeeMap(self.itemId)
end

function My:Dispose()
    self.itemId=0
    self.Index=0
    self:UnloadMode()
    self.IconTex =nil
    soonTool.Add(self.go,"FiveNextShowItem")
end

return My
