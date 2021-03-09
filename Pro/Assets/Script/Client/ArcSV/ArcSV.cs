using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ArcSV : MonoBehaviour {

    public GameObject target;
    UIPanel panel;

    List<Transform> childTrans;
    int childNum;
    void Start() {
        childTrans = new List<Transform>();
        panel = target.GetComponent<UIPanel>();
        childNum = transform.childCount;
        for (int i = 0; i < childNum; i++)
        {
            childTrans.Add(transform.GetChild(i));
        }
    }
    public float lerp = 320;
    float offsetY;
    float per;
    public void SetArcRotate()
    {
        offsetY = panel.clipOffset.y;
        per = (offsetY + 4) / lerp;
        transform.localRotation = Quaternion.Euler(0, 0, -80 * per);

        for (int i = 0; i < childNum; i++)
        {
            childTrans[i].localRotation = Quaternion.Euler(0, 0, 80 * per);
        }
    }

    public void SetDragStart()
    {
        //mDrag = true;
    }

    public void SetDragStop()
    {
        //mDrag = false;
    }

    private void Update()
    {
        //if(mDrag)
         SetArcRotate();
    }
}
