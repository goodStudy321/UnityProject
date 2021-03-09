using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 测试格子寻路角色
/// </summary>
public class TestGridPlayer : MonoBehaviour
{
    public Camera playerCam;
    public Camera minimapCam;

    //public GUIStyle bgStyle;

    /// <summary>
    /// 寻路组件
    /// </summary>
    public AsPathfinding mPathfinding = null;

    Unit unit;

    //void Awake()
    //{
    //    unit = new Unit();
    //    unit.UnitTrans = transform;
    //    mPathfinding = new AsPathfinding(unit, false);
    //}

    //void Start()
    //{

    //}

    //void Update()
    //{
    //    FindPath();
    //    if (mPathfinding != null && mPathfinding.PathFinish() == false)
    //    {
    //        //MoveMethod();
    //        mPathfinding.Move();
    //    }

    //    if (Input.GetKeyDown(KeyCode.T))
    //    {
    //        PathTool.PathMoveMgr.instance.RunPathMove(601, 1, true, PathTool.MoveOnPath.FaceType.FT_NONE, unit);
    //    }
    //}

    //private void FinCB(Unit unit, AsPathfinding.PathResultType prt)
    //{
    //    Debug.Log("Path : " + prt);
    //}

    //private void FindPath()
    //{
    //    if (mPathfinding == null)
    //    {
    //        iTrace.Error("LY", "Can not find pathfinding !!!  TestGridPlayer::FindPath");
    //        return;
    //    }

    //    /// 点击小地图 ///
    //    if (Input.GetButtonDown("Fire1") && Input.mousePosition.x > (Screen.width / 10) * 7F && Input.mousePosition.y < (Screen.height / 10) * 3.5F)
    //    {
    //        //Call minimap
    //        Ray ray = minimapCam.ScreenPointToRay(new Vector3(Input.mousePosition.x, Input.mousePosition.y, 0));
    //        RaycastHit hit;

    //        if (Physics.Raycast(ray, out hit, Mathf.Infinity))
    //        {
    //            mPathfinding.FindPathAndMove(0, transform.position, hit.point, 30f, -1f, FinCB);
    //        }
    //    }
    //    else if (Input.GetButtonDown("Fire1"))
    //    {
    //        //Call to the player map
    //        Ray ray = playerCam.ScreenPointToRay(new Vector3(Input.mousePosition.x, Input.mousePosition.y, 0));
    //        RaycastHit hit;

    //        if (Physics.Raycast(ray, out hit, Mathf.Infinity))
    //        {
    //            mPathfinding.FindPathAndMove(0, transform.position, hit.point, 30f, -1f, FinCB);
    //        }
    //    }
    //}

    ////private void MoveMethod()
    ////{
    ////    if (mPathfinding == null)
    ////    {
    ////        iTrace.Error("LY", "Can not find pathfinding !!!  TestGridPlayer::MoveMethod");
    ////        return;
    ////    }

    ////    List<Vector3> tPath = mPathfinding.CurPath;

    ////    if (tPath.Count > 0)
    ////    {
    ////        Vector3 direction = (tPath[0] - transform.position).normalized;

    ////        transform.position = Vector3.MoveTowards(transform.position, transform.position + direction, Time.deltaTime * 14F);
    ////        if (transform.position.x < tPath[0].x + 0.4F && transform.position.x > tPath[0].x - 0.4F && transform.position.z > tPath[0].z - 0.4F && transform.position.z < tPath[0].z + 0.4F)
    ////        {
    ////            tPath.RemoveAt(0);
    ////        }

    ////        RaycastHit[] hit = Physics.RaycastAll(transform.position + (Vector3.up * 20F), Vector3.down, 100);
    ////        float maxY = -Mathf.Infinity;
    ////        foreach (RaycastHit h in hit)
    ////        {
    ////            if (h.transform.tag == "Untagged")
    ////            {
    ////                if (maxY < h.point.y)
    ////                {
    ////                    maxY = h.point.y;
    ////                }
    ////            }
    ////        }
    ////        transform.position = new Vector3(transform.position.x, maxY + 1F, transform.position.z);
    ////    }
    ////}

    //void OnGUI()
    //{
    //    //GUI.Label(new Rect(0, 0, Screen.width, Screen.height), "", bgStyle);
    //}
}
