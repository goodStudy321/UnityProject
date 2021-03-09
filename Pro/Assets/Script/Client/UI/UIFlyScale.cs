using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UIFlyScale : UIFly
{

    public bool isScale = false;
    public float scaleIn = 0;
    public float scaleOut = 0;

    // Use this for initialization
    void Start () {

    }

    private float UpdateScale(float scale)
    {
        if(scale < 0)
        {
            scale = 0;
        }

        widget.transform.localScale = Vector3.one * scale;
        return scale;
    }

    protected override void CustomAwake()
    {
        if (isScale)
        {
            GetComponent();
        }
    }

    protected override void CustomEnable()
    {
        if (isScale == false || widget == null) return;
        if (scaleIn <= 0) return;
        UpdateScale(0.01f);
    }
    protected override void ExecuteFly()
    {
        float cur = Time.realtimeSinceStartup;
        if (lastTime != 0)
        {
            float offset = cur - lastTime;
            if (isScale)
            {
                if (scaleIn > 0 && scaleIn - offset >= 0)
                {
                    UpdateScale(offset / scaleIn);
                }
                if (scaleOut > 0 && time - offset <= scaleOut)
                {
                    UpdateScale((time - offset) / scaleOut);
                }
            }
            if (time - offset >= 0)
            {
                this.transform.localPosition = BezierTool.GetCubicCurvePoint(startPos, anchors1, anchors2, targetPos, offset / time);
            }
            else
            {

                this.transform.localPosition = BezierTool.GetCubicCurvePoint(startPos, anchors1, anchors2, targetPos, 1.0f);
                CurStatus = Status.End;
            }
        }
        else
        {
            CurStatus = Status.End;
        }
    }
}
