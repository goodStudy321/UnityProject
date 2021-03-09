using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

using Loong.Game;
using taecg.tools.mobileFastShadow;
using UnityEngine.SceneManagement;

public class PTLuaInfo
{
    public int id = 0;
    public Vector3 pos = Vector3.zero;
    public bool unlock = false;
    public int unlockLv = 0;
    public int unlockMissId = 0;
}


public class MapHelper
{
    public static readonly MapHelper instance = new MapHelper();


    private bool mSaveLoginCamamParm = false;
    private bool mLoginCamUseSRPP = false;
    private bool mLoginCamUseACE = false;

    private bool mSaveCharacterCamamParm = false;
    private bool mCharacterCamUseSRPP = false;
    private bool mCharacterCamUseACE = false;

    /// <summary>
    /// 正在转换的过程
    /// </summary>
    //private ChangeSceneBase mInChangeScene = null;

    private MobileFastShadow mMobileFastShadow = null;


    //public bool CanBreakChangeScene
    //{
    //    get
    //    {
    //        if (mInChangeScene == null || mInChangeScene.CanBreak == true)
    //            return true;

    //        return false;
    //    }
    //}
    public MobileFastShadow MFShadow
    {
        get { return mMobileFastShadow; }
        set { mMobileFastShadow = value; }
    }


    private MapHelper()
    {
        Init();
    }

    private void Init()
    {
        //EventMgr.Add("BreakChangeScene", OnBreakChangeScene);
        ////EventMgr.Add(EventKey.OnChangeScene, FinChangeScene);
    }


    public Vector3 GetMapStartPos()
    {
        return MapPathMgr.instance.MapStartPos;
    }

    public Vector3 GetMapEndPos()
    {
        return MapPathMgr.instance.MapEndPos;
    }

    public Vector3 GetMapCenterPos()
    {
        return MapPathMgr.instance.MapCenterPos;
    }

    /// <summary>
    /// 获取主角位置
    /// </summary>
    /// <returns></returns>
    public Vector3 GetOwnerPos()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return Vector3.zero;

        return unit.Position;
    }

    /// <summary>
    /// 获取自身在小地图中的位置缩放比例（左下角为起点）
    /// </summary>
    /// <returns></returns>
    //public Vector2 GetBokuPosSInMap()
    //{
    //    Vector3 oriStarPos = GetMapStartPos();
    //    //Vector3 oriEndPos = GetMapEndPos();
    //    Vector3 tempMapVec = GetMapEndPos() - GetMapStartPos();
    //    float mapWith = Mathf.Max(tempMapVec.x, tempMapVec.z);
    //    Vector3 newStarPos = oriStarPos;
    //    if (tempMapVec.x >= tempMapVec.z)
    //    {
    //        newStarPos.z = newStarPos.z - (tempMapVec.x - tempMapVec.z) / 2f;
    //    }
    //    else
    //    {
    //        newStarPos.x = newStarPos.x - (tempMapVec.z - tempMapVec.x) / 2f;
    //    }

    //    Vector3 tempBokuVec = GetOwnerPos() - newStarPos;

    //    Vector2 retVal = Vector2.zero;
    //    retVal.x = tempBokuVec.x / mapWith;
    //    retVal.y = tempBokuVec.z / mapWith;

    //    return retVal;
    //}
    public Vector2 GetBokuPosSInMap()
    {
        Vector3 oriStarPos = GetMapStartPos();
        Vector3 oriEndPos = GetMapEndPos();
        Vector3 oriCenterPos = GetMapCenterPos();
        float mapWith = Vector3.Distance(oriStarPos, oriEndPos);
        Vector3 newStarPos = oriCenterPos;
        newStarPos.x = oriCenterPos.x - mapWith / 2.0f;
        newStarPos.z = oriCenterPos.z - mapWith / 2.0f;

        Vector3 tempBokuVec = GetOwnerPos() - newStarPos;

        Vector2 retVal = Vector2.zero;
        retVal.x = tempBokuVec.x / mapWith;
        retVal.y = tempBokuVec.z / mapWith;

        return retVal;
    }

    /// <summary>
    /// 获取自身在小地图中的旋转值
    /// </summary>
    /// <returns></returns>
    public float GetBokuRotYInMap()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return 0;

        Vector3 tAngles = unit.UnitTrans.localEulerAngles;
        return tAngles.y;
    }


    //public Vector2 CalPosSInMap(Vector3 pos)
    //{
    //    Vector3 oriStarPos = GetMapStartPos();
    //    //Vector3 oriEndPos = GetMapEndPos();
    //    Vector3 tempMapVec = GetMapEndPos() - GetMapStartPos();
    //    float mapWith = Mathf.Max(tempMapVec.x, tempMapVec.z);
    //    Vector3 newStarPos = oriStarPos;
    //    if (tempMapVec.x >= tempMapVec.z)
    //    {
    //        newStarPos.z = newStarPos.z - (tempMapVec.x - tempMapVec.z) / 2f;
    //    }
    //    else
    //    {
    //        newStarPos.x = newStarPos.x - (tempMapVec.z - tempMapVec.x) / 2f;
    //    }

    //    Vector3 retVec = pos - newStarPos;

    //    Vector2 retVal = Vector2.zero;
    //    retVal.x = retVec.x / mapWith;
    //    retVal.y = retVec.z / mapWith;

    //    return retVal;
    //}
    public Vector2 CalPosSInMap(Vector3 pos)
    {
        Vector3 oriStarPos = GetMapStartPos();
        Vector3 oriEndPos = GetMapEndPos();
        Vector3 oriCenterPos = GetMapCenterPos();
        
        float mapWith = Vector3.Distance(oriStarPos, oriEndPos);
        Vector3 newStarPos = oriCenterPos;
        newStarPos.x = oriCenterPos.x - mapWith / 2.0f;
        newStarPos.z = oriCenterPos.z - mapWith / 2.0f;

        Vector3 tempBokuVec = pos - newStarPos;

        Vector2 retVal = Vector2.zero;
        retVal.x = tempBokuVec.x / mapWith;
        retVal.y = tempBokuVec.z / mapWith;

        return retVal;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="comPos"></param>
    /// <returns></returns>
    public Vector3 ChangePosToUICamera(Vector3 comPos)
    {
        return UICamera.mainCamera.WorldToScreenPoint(comPos);
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="comPos"></param>
    /// <returns></returns>
    public Vector3 ChangePosToUIPos(Vector3 comPos)
    {
        Vector3 retPos = ChangePosToUICamera(comPos);
        retPos.x = retPos.x - Screen.width / 2;
        retPos.y = retPos.y - Screen.height / 2;

        return retPos;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="posScal"></param>
    /// <returns></returns>
    public Vector3 GetMapNodePos(Vector2 posScal)
    {
        Vector3 oriStarPos = GetMapStartPos();
        //Vector3 oriEndPos = GetMapEndPos();
        Vector3 tempMapVec = GetMapEndPos() - GetMapStartPos();
        float mapWith = Mathf.Max(tempMapVec.x, tempMapVec.z);
        Vector3 newStarPos = oriStarPos;
        if (tempMapVec.x >= tempMapVec.z)
        {
            newStarPos.z = newStarPos.z - (tempMapVec.x - tempMapVec.z) / 2f;
        }
        else
        {
            newStarPos.x = newStarPos.x - (tempMapVec.z - tempMapVec.x) / 2f;
        }

        Vector3 calMapPos = new Vector3(newStarPos.x + mapWith * posScal.x, 0, newStarPos.z + mapWith * posScal.y);
        return calMapPos;
    }

    // 
    public Vector3 RotateAround(Vector3 rotPot, Vector3 cenPot, Vector3 axis, float angle)
    {
        Vector3 calPot = rotPot;
        Quaternion q = Quaternion.AngleAxis(angle, axis);
        Vector3 dif = calPot - cenPot;
        dif = q * dif;
        calPot = cenPot + dif;
        Vector3 retPot = calPot;
        //RotateAroundInternal(axis, angle * Mathf.Deg2Rad);

        return retPot;
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="posScal"></param>
    /// <returns></returns>
    public bool TryMoveToNewPos(Vector2 posScal, float stopDis)
    {
        Vector3 mapPos = GetMapNodePos(posScal);
        AsNode destNode = MapPathMgr.instance.FindClosestNode(mapPos,false, false);
        if(destNode == null || destNode.CanWalk == false)
        {
            iTrace.eLog("LY", "Position is not allowed for walk !!! " + destNode);
            UITip.LocalWarning(690018);
            return false;
        }

        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
        {
            return false;
        }
        unit.mUnitMove.StartNav(destNode.pos, stopDis);

        return true;
    }

    public bool TryMoveToNewPos2(Vector3 pos, float stopDis)
    {
        AsNode destNode = MapPathMgr.instance.FindClosestNode(pos, false, false);
        if (destNode == null || destNode.CanWalk == false)
        {
            iTrace.eLog("LY", "Position is not allowed for walk !!! " + destNode);
            UITip.LocalWarning(690018);
            return false;
        }

        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
        {
            return false;
        }
        unit.mUnitMove.StartNav(destNode.pos, stopDis);

        return true;
    }

    /// <summary>
    /// 获取跳转地图跳转口信息
    /// </summary>
    /// <returns></returns>
    public List<PTLuaInfo> GetChangeMapPor()
    {
        return MapPathMgr.instance.MapAssis.GetChangeMapPortals();
    }

    /// <summary>
    /// 判断是否输入禁止
    /// </summary>
    /// <returns></returns>
    public bool CanInput()
    {
        return InputMgr.instance.CanInput;
    }

    /// <summary>
    /// 检测当前场景是否能跳转
    /// </summary>
    /// <returns></returns>
    private bool CurSceneCanChange()
    {
        /// 当前场景Id ///
        int curSceneId = User.instance.SceneId;
        SceneInfo sInfo = SceneInfoManager.instance.Find((uint)curSceneId);
        if(sInfo == null)
        {
            return false;
        }

        if(sInfo.sceneType > 1)
        {
            return false;
        }

        return true;
    }

    /// <summary>
    /// 延迟转换场景
    /// </summary>
    /// <param name="sceneId"></param>
    /// <param name="delayTime"></param>
    //public void DelayChangeScene(int sceneId, float delayTime = -1)
    //{
    //    if (BreakChangeScene() == false)
    //    {
    //        iTrace.Log("LY", "In change scene !!! ");
    //        return;
    //    }

    //    mInChangeScene = new MissionChangeScene();
    //    float tDTime = delayTime;
    //    if (tDTime < 0)
    //    {
    //        tDTime = float.Parse(GlobalDataManager.instance.Find(12).num3);
    //    }
    //    mInChangeScene.Start(sceneId, tDTime, 0, FinishChangeScene);
    //}

    public bool CheckSceneResExist(int sceneId)
    {
        if (sceneId == 0)
            return true;

        SceneInfo tInfo = SceneInfoManager.instance.Find((uint)sceneId);
        if(tInfo == null || tInfo.resName == null || tInfo.resName.list == null || tInfo.resName.list.Count <= 0)
        {
#if GAME_DEBUG
            iTrace.Warning("Loong", "sceneID:{0} not exist resName", sceneId);
#endif
            return false;
        }

        string resName = tInfo.resName.list[0] + ".unity";
        string nextMapData = string.Concat(tInfo.mapId.ToString(), ".bytes");
        string nextMapBlock = string.Concat(tInfo.mapId.ToString(), "_block.prefab");
        return (AssetMgr.Instance.Exist(resName) && AssetMgr.Instance.Exist(nextMapData) && AssetMgr.Instance.Exist(nextMapBlock));
    }

    
    public void ChangeSceneCom(int sceneId, uint fromPorId = 0, uint toPorId = 0)
    {
        if(CheckSceneResExist(sceneId) == false)
        {
            UITip.LocalLog(690010);
            UIMgr.Open("UIDownload");
            iTrace.Error("LY", "场景资源尚未加载完成!");
            return;
        }

        Unit playerUnit = InputVectorMove.instance.MoveUnit;
        if (playerUnit == null)
        {
            iTrace.eError("LY", "Player unit is miss !!! ");
            return;
        }

        playerUnit.mUnitMove.Pathfinding.FindPathAndMove((uint)sceneId, fromPorId, toPorId, false);
    }

    /// <summary>
    /// 完整寻路行走
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="endPosition"></param>
    /// <param name="stopDis"></param>
    /// <param name="finCB"></param>
    public void FindPathAndMoveDetail(uint mapId, Vector3 endPosition, float stopDis = -1, Action<Unit, AsPathfinding.PathResultType> finCB = null)
    {
        Unit playerUnit = InputVectorMove.instance.MoveUnit;
        if (playerUnit == null)
        {
            iTrace.eError("LY", "Player unit is miss !!! ");
            return;
        }

        if (CheckSceneResExist((int)mapId) == false)
        {
            UITip.LocalLog(690010);
            UIMgr.Open("UIDownload");
            if (finCB != null)
            {
                finCB(playerUnit, AsPathfinding.PathResultType.PRT_CALL_BREAK);
            }
            iTrace.Error("LY", "场景资源尚未加载完成!");
            return;
        }

        playerUnit.mUnitMove.Pathfinding.FindPathAndMoveDetail(mapId, playerUnit.Position,
            endPosition, -1f, stopDis, finCB);
    }

    /// <summary>
    /// 小飞鞋
    /// </summary>
    /// <param name="sceneId"></param>
    /// <param name="desPos"></param>
    /// <param name="dis"></param>
    /// <param name="finCB"></param>
    public void LittleFlyShoes(int sceneId, Vector3 desPos, float dis = -1, bool showTip = false,
        float pTime = 0.5f, float afTime = 0f, Action<Unit, AsPathfinding.PathResultType> finCB = null)
    {
        Unit playerUnit = InputVectorMove.instance.MoveUnit;
        if(playerUnit == null)
        {
            iTrace.eError("LY", "Player unit is miss !!! ");
            return;
        }

        if (CheckSceneResExist((int)sceneId) == false)
        {
            UITip.LocalLog(690010);
            UIMgr.Open("UIDownload");
            if (finCB != null)
            {
                finCB(playerUnit, AsPathfinding.PathResultType.PRT_CALL_BREAK);
            }
            iTrace.Error("LY", "场景资源尚未加载完成!");
            return;
        }

        playerUnit.mUnitMove.Pathfinding.FindPathFlyShoes(sceneId, desPos, dis, showTip, pTime, afTime, finCB);
    }

    /// <summary>
    /// 获取周边可以站立位置
    /// </summary>
    /// <param name="oriPos"></param>
    /// <returns></returns>
    public Vector3 GetCanStandPos(Vector3 desPos, float dis)
    {
        Vector3 oriVec = new Vector3(1, 0, 0);
        oriVec = oriVec.normalized;
        AsNode desNode = null;
        for (int a = 0; a < 8; a++)
        {
            Vector3 newVec = Quaternion.Euler(0, 45 * a, 0) * oriVec;
            Vector3 newPos = desPos + newVec * dis;
            desNode = MapPathMgr.instance.FindClosestNode(newPos, false);
            if (desNode != null && desNode.CanWalk == true && desNode.IsBound == false)
            {
                return desNode.pos;
            }
        }

        iTrace.eError("LY", "No stand pos around !!!  oriPos : " + desPos);
        return desPos;
    }

    /// <summary>
    /// 获取位置
    /// </summary>
    /// <param name="point">服务器传过来的参数</param>
    /// <returns></returns>
    public Vector3 GetPositon(long point)
    {
        Vector3 pos = Vector3.zero;
        long dir = point >> 40;
        dir = dir << 40;
        long posZ = (point - dir) >> 20;
        pos.z = posZ;
        posZ = posZ << 20;
        long posX = point - dir - posZ;
        pos.x = posX;
        pos = MapPathMgr.instance.PosServerToClient((int)pos.x, (int)pos.z);
        return pos;
    }

    public AwakenPortalFig GetCtrlPortalById(int portalId)
    {
        return MapPathMgr.instance.MapAssis.GetAwakenPortalFigById((uint)portalId);
    }

    public bool SetShadowTarget(GameObject go)
    {
        if(mMobileFastShadow == null || go == null)
        {
            return false;
        }

        mMobileFastShadow.FollowTarget = go;
        return true;
    }

    public bool SetSceneAmbientColor(Vector4 col)
    {
        //RenderSettings.ambientMode == UnityEngine.Rendering.AmbientMode.

        RenderSettings.ambientLight = new Color(col.x, col.y, col.z, col.w);
        return true;
    }

    public bool SetSceneFogColor(Vector4 col)
    {
        if(RenderSettings.fog == false)
        {
            return false;
        }

        RenderSettings.fogColor = new Color(col.x, col.y, col.z, col.w);
        return true;
    }

    public bool SetSceneFogStart(float val)
    {
        if (RenderSettings.fog == false)
        {
            return false;
        }

        RenderSettings.fogStartDistance = val;
        return true;
    }

    public bool SetSceneFogEnd(float val)
    {
        if (RenderSettings.fog == false)
        {
            return false;
        }

        RenderSettings.fogEndDistance = val;
        return true;
    }

    public void ChangeLoginCamQuality(GameObject camObj, int qLv)
    {
        SleekRender.SleekRenderPostProcess tSRPP = camObj.GetComponent<SleekRender.SleekRenderPostProcess>();
        AmplifyColorEffect tACE = camObj.GetComponent<AmplifyColorEffect>();
        if(mSaveLoginCamamParm == false)
        {
            mLoginCamUseSRPP = tSRPP.enabled;
            mLoginCamUseACE = tACE.enabled;
            mSaveLoginCamamParm = true;
        }

        if(qLv >= 3)
        {
            if(mLoginCamUseSRPP == true)
            {
                tSRPP.enabled = true;
            }
            if (mLoginCamUseACE == true)
            {
                tACE.enabled = true;
            }
        }
        else if(qLv == 2)
        {
            tSRPP.enabled = false;
            if (mLoginCamUseACE == true)
            {
                tACE.enabled = true;
            }
        }
        else
        {
            tSRPP.enabled = false;
            tACE.enabled = false;
        }
    }

    public void ChangeCharacterCamQuality(GameObject camObj, int qLv)
    {
        SleekRender.SleekRenderPostProcess tSRPP = camObj.GetComponent<SleekRender.SleekRenderPostProcess>();
        AmplifyColorEffect tACE = camObj.GetComponent<AmplifyColorEffect>();
        if (mSaveCharacterCamamParm == false)
        {
            mCharacterCamUseSRPP = tSRPP.enabled;
            mCharacterCamUseACE = tACE.enabled;
            mSaveCharacterCamamParm = true;
        }

        if (qLv >= 3)
        {
            if (mCharacterCamUseSRPP == true)
            {
                tSRPP.enabled = true;
            }
            if (mCharacterCamUseACE == true)
            {
                tACE.enabled = true;
            }
        }
        else if (qLv == 2)
        {
            tSRPP.enabled = false;
            if (mCharacterCamUseACE == true)
            {
                tACE.enabled = true;
            }
        }
        else
        {
            tSRPP.enabled = false;
            tACE.enabled = false;
        }
    }

    public void FindObj(string name,  string state)
    {
        GameObject[] allSceneObjs = (GameObject[])Resources.FindObjectsOfTypeAll(typeof(GameObject));
        foreach (var item in allSceneObjs)
        {
            //GameObject go = Utility.FindNode(item, name);
            if (item.name == name)
            {
                item.SetActive(state == "1");
            }
        }
    }

    public void SetCurRenderCam(Camera cam, bool isAnim = false)
    {
        CameraMgr.SetSceneRtToCurCam(cam, isAnim);
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="camObj"></param>
    public void SetCurRenderCamByObj(GameObject camObj, bool isAnim = false)
    {
        if(camObj == null)
        {
            return;
        }

        Camera cam = camObj.GetComponent<Camera>();
        SetCurRenderCam(cam, isAnim);
    }

    /// <summary>
    /// 
    /// </summary>
    public void SetMainToCurRenderCam()
    {
        SetCurRenderCam(CameraMgr.Main, false);
    }
}
