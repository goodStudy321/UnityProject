using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UIRotateMod : MonoBehaviour
{

    /// <summary>
    /// ģ�͸����
    /// </summary>
    public Transform root = null;
    public float mRotateSpeed = 20;

    /// <summary>
    /// true:���Ҽ������ĵ�һ���ӽڵ�Ϊ��ת����
    /// </summary>
    public bool isShell = true;
    private Transform trans = null;

    void Start()
    {
        if (root == null) root = transform;
        UIEventListener.Get(this.gameObject).onDrag += OnDragUI;
    }

    private void SetTrans()
    {
        int length = root.childCount;
        for (int i = 0; i < length; i++)
        {
            Transform c = root.GetChild(i);
            if (c.gameObject.activeSelf)
            {
                //                 if (isShell)
                //                 {
                if (c.childCount > 0)
                {
                    trans = c.GetChild(0);
                }
                /*          }*/
                //                 else
                //                 {
                //                     trans = c;
                // 
                //                 }
            }
        }
    }

    public void OnDragUI(GameObject go, Vector2 delta)
    {
        if (trans == null)
        {
            SetTrans();
        }
        else if (isShell && !trans.parent.gameObject.activeSelf)
        {
            SetTrans();
        }
        else if (!trans.gameObject.activeSelf)
        {
            SetTrans();
        }
        if (trans == null)
        {
            return;
        }
        Vector3 angle = trans.eulerAngles;
        angle.y -= delta.x * Time.deltaTime * mRotateSpeed;
        trans.eulerAngles = angle;
    }
}
