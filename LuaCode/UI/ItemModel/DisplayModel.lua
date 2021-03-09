--[[
展示模型
]]
DisplayModel=Super:New{Name="DisplayModel"}
local My = DisplayModel
My.tp=nil
My.data=nil
My.pos=nil

function My:Init(go)
    self.go=go
    local trans = go.transform
    self.ModelRoot=TransTool.FindChild(trans,"Model").transform
    self.roleSkin=ObjPool.Get(RoleSkin)
    self.roleSkin.eLoadModelCB:Add(self.SetPos,self)
    My.pos=nil
end

function My:LoadTex()
    self.roleSkin:DestroyUIModel()
    local isExit=AssetMgr:Exist(self.path..".prefab")
    if isExit~=true then return end	
    if My.tp==1 then
        if not self.skinList then self.skinList={} end
		self.skinList[1]=My.data.id
        self.roleSkin:CreateSelfT(self.ModelRoot,self.skinList)
    else --root,path,rota,pos
        local temp = My.data
        local pos = temp.pos or Vector3.zero
        local rota = temp.rotate or Vector3.zero
        local model = #temp.model==1 and temp.model[1] or temp.model[User.instance.MapData.Sex+1]
        self.roleSkin:LoadModel(self.ModelRoot,model,rota,pos)
    end
end

function My:SetPos(go)
    local temp = My.data
    local pos = My.pos
    if not pos then 
       pos = temp[self.idName] 
        if not pos then pos=temp.pos or Vector3.zero end
    end
    local rota = temp.rotate 
    go.transform.localScale=Vector3.one*345
    go.transform.localPosition=pos
    if rota then 
        go.transform.localEulerAngles=rota
    end
    local eff = go:GetComponent(typeof(UIEffBinding))
	if not eff then eff=go:AddComponent(typeof(UIEffBinding)) end
    self.roleSkin.uiModel=go
    local layer = self.layer or 22
    local laName = layer==22 and "ItemModel" or "UIModel"
    eff.mNameLayer=laName
    LayerTool.Set(go, layer)
end

function My:LoadCb(obj)
    self.texture.mainTexture=obj
end

function My.IsTrue(type_id)
    local istrue,path = false
    My.data=ItemModel[tostring(type_id)]
	if My.data and My.data.model then  --看是否是展示模型（时装or模型)
		istrue=true
		local model = My.data.model
		path = #model==1 and model[1] or model[User.instance.MapData.Sex+1]	
        local temp = FashionAdvCfg[tostring(type_id)]
        if temp and temp.type==1 then 
            My.tp=1 --人物时装
        else
            My.tp=2 --普通模型
        end	
	end
	return istrue,path
end

function My:Dispose()
    self.layer=nil
    self.roleSkin.eLoadModelCB:Remove(self.SetPos,self)
    if self.roleSkin then ObjPool.Add(self.roleSkin) self.roleSkin=nil end
end
