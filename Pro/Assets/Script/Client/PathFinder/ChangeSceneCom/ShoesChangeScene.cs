//using System;
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;

//#if UNITY_EDITOR
//using UnityEditor;
//#endif

//using Loong.Game;


///// <summary>
///// 任务转换场景
///// </summary>
//public class ShoesChangeScene : ChangeSceneBase
//{
//    /// <summary>
//    /// 飞鞋调用范围
//    /// </summary>
//    public static float canFlyDis = 15f;

//    private Vector3 shoesDesPos;
//    private float shoesDis = -1;
//    private Action<Unit, AsPathfinding.PathResultType> shoesFinCB = null;


//    public ShoesChangeScene()
//    {
        
//    }

//    public virtual void Start(int sceneId, Vector3 desPos, float dis = -1, float preTime = 0, float afterTime = 0, 
//        Action finCB = null,  Action<Unit, AsPathfinding.PathResultType> finShoesCB = null)
//    {
//        base.Start(sceneId, preTime, afterTime, finCB);

//        shoesDesPos = desPos;
//        shoesDis = dis;
//        shoesFinCB = finShoesCB;
//    }

//    protected override void FinPreWait()
//    {
//        if (mSceneId > 0)
//        {
//            NetworkMgr.ReqPreEnter(mSceneId);
//        }
//        else
//        {
//            Unit playerUnit = InputVectorMove.instance.MoveUnit;
//            if (playerUnit != null)
//            {
//                FlySameScene(playerUnit, shoesDesPos, shoesDis, shoesFinCB);
//            }

//            shoesDesPos = Vector3.zero;
//            shoesDis = -1;
//            shoesFinCB = null;
//        }
//        base.FinPreWait();
//    }

//    protected override void FinChangScene(params object[] args)
//    {
//        Unit playerUnit = InputVectorMove.instance.MoveUnit;
//        if (mSceneId == User.instance.SceneId)
//        {
//            if (playerUnit != null)
//            {
//                FlySameScene(playerUnit, shoesDesPos, shoesDis, shoesFinCB);
//            }
//        }
//        else
//        {
//            if(shoesFinCB != null)
//            {
//                shoesFinCB(playerUnit, AsPathfinding.PathResultType.PRT_CHANGE_SCENE_BREAK);
//            }
//        }
//        shoesDesPos = Vector3.zero;
//        shoesDis = -1;
//        shoesFinCB = null;
//        base.FinChangScene(args);
//    }


//    /// <summary>
//    /// 同场景飞鞋
//    /// </summary>
//    /// <param name="playerUnit"></param>
//    /// <param name="desPos"></param>
//    private void FlySameScene(Unit playerUnit, Vector3 desPos, float dis = -1, Action<Unit, AsPathfinding.PathResultType> finShoesCB = null)
//    {
//        if (dis <= 0)
//        {
//            playerUnit.Position = desPos;
//            if (finShoesCB != null)
//            {
//                finShoesCB(playerUnit, AsPathfinding.PathResultType.PRT_SHOES_SUC);
//            }
//            return;
//        }

//        float desDis = Vector3.Distance(playerUnit.Position, desPos);
//        if (desDis < dis)
//        {
//            if (finShoesCB != null)
//            {
//                finShoesCB(playerUnit, AsPathfinding.PathResultType.PRT_SHOES_SUC);
//            }
//            return;
//        }

//        /// 飞鞋 ///
//        if (desDis > canFlyDis)
//        {
//            Vector3 oriVec = new Vector3(1, 0, 0);
//            oriVec = oriVec.normalized;
//            AsNode desNode = null;
//            for (int a = 0; a < 8; a++)
//            {
//                Vector3 newVec = Quaternion.Euler(0, 45 * a, 0) * oriVec;
//                Vector3 newPos = desPos + newVec * dis;
//                desNode = MapPathMgr.instance.FindClosestNode(newPos, false);
//                if (desNode != null && desNode.CanWalk == true)
//                {
//                    //playerUnit.Position = newPos;
//                    NetMove.RequestChangePosDir(playerUnit, newPos);
//                    if (finShoesCB != null)
//                    {
//                        finShoesCB(playerUnit, AsPathfinding.PathResultType.PRT_SHOES_SUC);
//                    }
//                    return;
//                }
//            }

//            iTrace.eError("LY", "No little fly shoes pos !!! ");
//        }
//        /// 寻路 ///
//        else
//        {
//            playerUnit.mUnitMove.StartNav(desPos, dis, 0, finShoesCB);
//        }
//    }
//}
