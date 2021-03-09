using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 显示隐藏跳转口特效
/// </summary>
[ExecuteInEditMode]
public class DisplayZone : MonoBehaviour
{
    /// <summary>
    /// 显示范围大小
    /// </summary>
    private float colRadius = 5f;
    public float ColRadius
    {
        set
        {
            colRadius = value;
            UpdateRadius();
        }
    }

    private GameObject mParentObj = null;
    public Collider mAreaCol = null;
    private List<GameObject> mCtrlObjs = new List<GameObject>();

    private void Awake()
    {
        if (transform.parent == null)
            return;

        mParentObj = transform.parent.gameObject;

        mAreaCol = gameObject.GetComponent<Collider>();
        if(mAreaCol == null)
        {
            mAreaCol = gameObject.AddComponent<SphereCollider>();
            ((SphereCollider)mAreaCol).radius = colRadius;
            ((SphereCollider)mAreaCol).isTrigger = true;
            Rigidbody tRBD = gameObject.AddComponent<Rigidbody>();
            tRBD.useGravity = false;
            tRBD.isKinematic = true;
        }

        for (int a = 0; a < mParentObj.transform.childCount; a++)
        {
            GameObject tObj = mParentObj.transform.GetChild(a).gameObject;
            if(tObj != null && tObj != gameObject)
            {
                mCtrlObjs.Add(tObj);
            }
        }
        if (InputVectorMove.instance.MoveUnit != null && InputVectorMove.instance.MoveUnit.mUnitMove != null)
        {
            float dis = Vector2.Distance(new Vector2(transform.position.x, transform.position.z), 
                new Vector2(InputVectorMove.instance.MoveUnit.Position.x, InputVectorMove.instance.MoveUnit.Position.z));
            SetChildShow(dis <= colRadius);
        }
        else
        {
            SetChildShow(false);
        }
    }

    private void UpdateRadius()
    {
        if (mAreaCol == null)
        {
            mAreaCol = gameObject.AddComponent<SphereCollider>();
        }
        if (mAreaCol is SphereCollider)
        {
            ((SphereCollider)mAreaCol).radius = colRadius;
        }
    }

    private void Start()
    {
        
    }

    private void OnTriggerEnter(Collider other)
    {
        if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null)
            return;

        if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name)
            return;

        SetChildShow(true);
    }

    private void OnTriggerExit(Collider other)
    {
        if (InputVectorMove.instance.MoveUnit == null || InputVectorMove.instance.MoveUnit.mUnitMove == null)
            return;

        if (other.name != InputVectorMove.instance.MoveUnit.UnitTrans.name)
            return;

        SetChildShow(false);
    }

    public void SetChildShow(bool isShow)
    {
        if(mCtrlObjs == null)
        {
            return;
        }

        for(int a =0; a < mCtrlObjs.Count; a++)
        {
            if (mCtrlObjs[a] != null)
            {
                mCtrlObjs[a].SetActive(isShow);
            }
        }
    }
}
