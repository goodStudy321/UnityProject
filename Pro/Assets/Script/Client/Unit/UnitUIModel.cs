using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitUIModel
{
    private enum ViewType
    {
        None,
        MainMissionView,
        DialogLeft,
        DialogRight,
    }
    private ViewType mType;

    private Camera mModelCamera;
    private Unit mUnit = null;

    #region 参数
    /// <summary>
    /// 摄像机Y轴比例
    /// </summary>
    private const float Y_Ratio = 1.0f;
    #endregion

    /// <summary>
    /// 主线任务窗口
    /// </summary>
    private Rect mMainMissionView = new Rect(0.043f, 0.716f, 0.22f, 1);
    /// <summary>
    /// 对话框靠左
    /// </summary>
    private Rect mDialogViewLeft= new Rect(0.0f, 0.0f, 0.75f, 0.5f);
    /// <summary>
    /// 对话框靠右
    /// </summary>
    private Rect mDialogViewRight = new Rect(0.76f, 0.269f, 0.29f, 1);

    private Camera CreateCamera(CapsuleCollider collider)
    {
        GameObject go = new GameObject(TagTool.ModelCamera);
        go.tag = TagTool.ModelCamera;
        Camera camera = go.AddComponent<Camera>();
        camera.clearFlags = CameraClearFlags.Depth;
        int mask = 1 << LayerTool.ShadowCaster | 1 << LayerTool.UIModel;
        camera.cullingMask = mask;
        camera.orthographic = false;
        camera.fieldOfView = 28;
        //camera.orthographicSize = collider.radius;
        camera.nearClipPlane = 0.01f;
        camera.farClipPlane = 30.0f;
        return camera;
    }

    public void CreateModel(string modelName, int viewType)
    {
        Clean();
        mType = (ViewType)viewType;
        if (string.IsNullOrEmpty(modelName))
        {
            iTrace.eError("hs", "modelName is null!!");
            return;
        }

        AssetMgr.LoadPrefab(modelName, CreateModelComplete);
    }


    private void CreateModelComplete(GameObject go)
    {
        LayerTool.Set(go.transform, LayerTool.UIModel);
        go.SetActive(false);
        go.SetActive(true);
        CapsuleCollider collider = Loong.Game.ComTool.Get<CapsuleCollider>(go.transform);
        if (!collider) return;
        if (mModelCamera == null) mModelCamera = CreateCamera(collider);
        if (mModelCamera)
        {
            mModelCamera.transform.parent = go.transform;
            mModelCamera.transform.localPosition = new Vector3(collider.center.x, collider.height  * Y_Ratio, +3.0f);
            mModelCamera.transform.localEulerAngles = new Vector3(15.0f, 180.0f, 0);
            mModelCamera.rect = GetRect();
        }
    }

    public void CreateUnit(uint unitId, int type , int viewType )
    {
        Clean();
        mType = (ViewType)viewType;
        switch ((UnitType)type)
        {
            case UnitType.NPC:
                mUnit = CreateNPC(unitId);
                break;
        }
    }

    public Unit CreateNPC(uint unitId)
    {
        NPCInfo info = NPCInfoManager.instance.Find(unitId);
        if (info == null)
        {
            Loong.Game.iTrace.eError("HS", string.Format("NPC ID:{0} 不存在", unitId));
            return null;
        }
        RoleBase role = RoleBaseManager.instance.Find(info.modeId);
        if (role == null)
        {
            Loong.Game.iTrace.eError("HS", string.Format("NPC ID:{0} 配置的模型;{1}不存在", unitId,info.modeId));
            return null;
        }
        //AssetMgr.LoadPrefab(role.modelPath, CreateModelComplete);
        CampType camp = (CampType)User.instance.MapData.Camp;
        return UnitMgr.instance.CreateUnit(GuidTool.GenDateLong(), info.id, info.title, Vector3.zero, (float)180, camp, CreateUnitComplete);
    }

    private void CreateUnitComplete(Unit unit)
    {
        CreateModelComplete(unit.UnitTrans.gameObject);
    }

    private Rect GetRect()
    {
        if (mType == ViewType.MainMissionView)
            return mMainMissionView;
        else if (mType == ViewType.DialogLeft)
            return mDialogViewLeft;
        else if (mType == ViewType.DialogRight)
            return mDialogViewRight;
        return new Rect(0, 0, 1, 1);
    }

    public void Clean()
    {
        if (mUnit != null) mUnit.Destroy();
    }

    public void Dispose()
    {
        if (mUnit != null)
        {
            mUnit.Destroy();
            mUnit = null;
        }
        if(mModelCamera != null)
        {
            if (mModelCamera.transform.parent != null)
            {
                Object.Destroy(mModelCamera.transform.parent.gameObject);
            }
            mModelCamera = null;
        }
    }
}

