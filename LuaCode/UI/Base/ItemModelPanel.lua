--[[
展示模型
]]
ItemModelPanel=Super:New{Name="ItemModelPanel"}
local My = ItemModelPanel

function My:Init(type_id,parent,pos,depth)
    self.data=ItemModel[tostring(type_id)]
	if not self.data then return end
	local model = self.data.model
	local mm = nil
	if #model==1 then 
		mm=model[1] 
	else 
		mm=model[User.instance.MapData.Sex+1]
	end
	if not mm then return end	
	local isExit=AssetMgr:Exist(mm..".prefab")
    if isExit~=true then return end
    
    self.modelPath=mm
    self.parent=parent
    self.pos=pos
    self.depth=depth
    LoadPrefab("ItemModelPanel",GbjHandler(self.LoadModelCb,self))
end

function My:LoadModelCb(go)
	if LuaTool.IsNull(go) then return end
	go:SetActive(true)
	go.transform.parent=self.parent
	go.transform.localScale=Vector3.one
	go.transform.localPosition=self.pos
    self.go=go
    
    local trans = go.transform
	self.Model=TransTool.FindChild(trans,"bg/Model")
    local panel = go:GetComponent(typeof(UIPanel))
    panel.depth=self.depth
	self.modCam=ComTool.Get(Camera,trans,"modCam",self.Name,false)
	self.modCam.transform.localPosition=Vector3.New(380,10,-1607)
    self.modCam.depth=UIMgr.HCam.depth+1
    
	LoadPrefab(self.modelPath,GbjHandler(self.LoadModel,self))
end

function My:LoadModel(go)
	go:SetActive(true)
	go.transform.parent=self.Model.transform
	go.transform.localPosition=self.data.pos
	go.transform.localScale=Vector3.one*345
	if self.data.rotate then 
		go.transform.localEulerAngles=self.data.rotate
	end

	local eff = go:GetComponent(typeof(UIEffBinding))
	if not eff then eff=go:AddComponent(typeof(UIEffBinding)) end
	eff.mNameLayer="ItemModel"
	LayerTool.Set(go,22)
	self.model=go
end

function My:Dispose()
    if LuaTool.IsNull(self.go)~=true then 
        local name = self.go.name..".prefab"
        GbjPool:Add(self.go)
        AssetMgr:Unload(name,false)
    end
    if LuaTool.IsNull(self.model)~=true then 
        local name = self.model.name..".prefab"
        Destroy(self.model) 
        AssetMgr:Unload(name,false)
    end
    self.data=nil
end