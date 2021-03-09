using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 显示控制区域
/// </summary>
//[ExecuteInEditMode]
public class AppearCtrlZone : MonoBehaviour
{
    /// <summary>
    /// 节点名称
    /// </summary>
    public string mZoneName = "";
    /// <summary>
    /// 显示区域名称
    /// </summary>
    public List<string> mShowZoneNames = new List<string>();
    /// <summary>
    /// 隐藏区域名称
    /// </summary>
    public List<string> mHideZoneNames = new List<string>();

    private void Awake()
    {
        
    }

    private void Start()
    {
        
    }

    void OnTriggerEnter(Collider other)
    {
        Unit mainUnit = InputVectorMove.instance.MoveUnit;
        if (mainUnit == null || mainUnit.UnitTrans == null)
            return;

        if(other.transform == mainUnit.UnitTrans)
        {
            AppearCtrlZoneMgr.instance.EnterAppearZone(this);
        }
    }

    void OnTriggerExit(Collider other)
    {
        Unit mainUnit = InputVectorMove.instance.MoveUnit;
        if (mainUnit == null || mainUnit.UnitTrans == null)
            return;

        if (other.transform == mainUnit.UnitTrans)
        {
            AppearCtrlZoneMgr.instance.ExitAppearZone(this);
        }
    }

    /// <summary>
    /// 进入区域
    /// </summary>
    public void EnterZone(GameObject rootObj)
    {
        if (rootObj == null)
            return;

        for(int a = 0; a < rootObj.transform.childCount; a++)
        {
            GameObject cObj = rootObj.transform.GetChild(a).gameObject;
            if(mShowZoneNames.Contains(cObj.name))
            {
                cObj.SetActive(true);
            }
            else if(mHideZoneNames.Contains(cObj.name))
            {
                cObj.SetActive(false);
            }
        }
    }

    /// <summary>
    /// 退出区域
    /// </summary>
    public void ExitZone(GameObject rootObj)
    {

    }
}
