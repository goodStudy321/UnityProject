using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class UIFlyAlpha : UIFly
{

    public bool isFade = false;
    public float fadeIn = 0;
    public float fadeOut = 0;

    // Use this for initialization
    void Start () {

    }

    private float UpdateFade(float alpha)
    {
        widget.color = new Color(color.r, color.g, color.b, alpha);
        return alpha;
    }

    protected override void CustomAwake()
    {
        if (isFade)
        {
            GetComponent();
        }
    }

    protected override void CustomEnable()
    {
        if (isFade == false || widget == null) return;
        UpdateFade(0);
    }
    protected override void ExecuteFly()
    {
        float cur = Time.realtimeSinceStartup;
        if (lastTime != 0)
        {
            float offset = cur - lastTime;
            if (isFade)
            {
                if (fadeIn - offset >= 0)
                {
                    UpdateFade(offset / fadeIn);
                }
                if (time - offset <= fadeOut)
                {
                    UpdateFade((time - offset) / fadeOut);
                }
            }
            if (time - offset >= 0)
            {
                this.transform.localPosition = BezierTool.GetCubicCurvePoint(startPos, anchors1, anchors2, targetPos, offset / time);
            }
            else
            {
                CurStatus = Status.End;
            }
        }
        else
        {
            CurStatus = Status.End;
        }
    }
}
