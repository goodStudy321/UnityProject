using UnityEngine;
using System.Collections;

public class ChainLightningInfo
{
    public float speed;
    public float acceleration;
    public Vector3 startPos;
    public Vector3 lastPos;
    public Vector3 curPos;
    public Vector3 endPos;
    public Vector3 forward;
    public bool isPlayingEffect;
    public GameObject effect;
    public Unit target;
    public bool isHitTarget;
    public int hideEffectFrame;

    public void Clear(string effectName)
    {
        if (effectName == null)
            return;
        if (effect == null)
            return;
        target = null;
        ShowEffectMgr.instance.AddToPool(effect);
    }
}
