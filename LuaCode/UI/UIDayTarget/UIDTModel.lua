UIDTModel = Super:New{Name = "UIDTModel"}

require("Tool/MyGbjPool")

local M = UIDTModel

M.mTexList = {}

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    self.mTrans = trans
    self.mIcon = G(UITexture, trans, "Icon")
    self.mScore = G(UILabel, trans, "Score")
    self.mBtnRight = FC(trans, "BtnRight")
    self.mBtnLeft = FC(trans, "BtnLeft")

    self.mGbjPool = ObjPool.Get(MyGbjPool)

    S(self.mBtnRight, self.OnRight, self)
    S(self.mBtnLeft, self.OnLeft, self)

    self:UpdateData()
end

function M:OnRight()
    local modelPath, icon, pos, euler, score, index = DayTargetMgr:GetModel(self.mCurIndex, false)
    self:UpdateModel(modelPath, icon, pos, euler, score, index)
end

function M:OnLeft()
    local modelPath, icon, pos, euler, score, index = DayTargetMgr:GetModel(self.mCurIndex, true)
    self:UpdateModel(modelPath, icon, pos, euler, score, index)
end

function M:UpdateModel(modelPath, icon, pos, euler, score, index)
    if not modelPath then return end
    if self.mCurModel and self.mCurModel.name == modelPath then return end
    self.mCurIndex = index
    self.mPos = Vector3(pos.x, pos.y, pos.z)
    self.mEuler = euler
    local go = self.mGbjPool:Get(modelPath)
    if go then
        self:SetModel(go)
    else
        LoadPrefab(modelPath,GbjHandler(self.SetModel,self)) 
    end

    self:UpDateScore(score)
    self:UpdateIcon(icon)
    self:UpdateBtn()
end

function M:UpdateBtn()
    local modelPath = DayTargetMgr:GetModel(self.mCurIndex, false)
    self.mBtnRight:SetActive(modelPath ~= nil)
    local modelPath = DayTargetMgr:GetModel(self.mCurIndex, true)
    self.mBtnLeft:SetActive(modelPath ~= nil)
end

function M:UpdateData()
    local modelPath, icon, pos, euler, score, index = DayTargetMgr:GetCurModel()
    self:UpdateModel(modelPath, icon, pos, euler, score, index)
end

function M:UpDateScore(score)
    self.mScore.text = score
end

function M:UpdateIcon(icon)
    AssetMgr:Load(icon, ObjHandler(self.SetIcon, self))
end

function M:SetModel(go)
    if  not LuaTool.IsNull(self.mTrans) then
        self.mGbjPool:Add(self.mCurModel)
        self.mCurModel = go
        go.transform.parent = self.mTrans
        go.transform.localScale = Vector3(360,360,360)
        go.transform.localPosition = self.mPos
        go.transform.localRotation = Quaternion.Euler(self.mEuler.x, self.mEuler.y, self.mEuler.z)
    else
        self:Unload(go)
    end
end

function M:SetIcon(tex)
    if self.mIcon then
        self.mIcon.mainTexture = tex
        self.mIcon:MakePixelPerfect()
        table.insert(self.mTexList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end


function M:Dispose()
    self.mCurModel = nil
    self.mCurIndex = nil
    ObjPool.Add(self.mGbjPool)
    self.mGbjPool = nil
    AssetTool.UnloadTex(self.mTexList)
    TableTool.ClearUserData(self)
end

return M