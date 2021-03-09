using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitUIAnimEvent : MonoBehaviour
{

    private Animation anim;
    private AnimationClip scn;
    public string startClipName;
    public string endClipName;
    public bool isCrossFade = true;
    public float cfTime = 0.2f;


    // Use this for initialization
    void Awake () {
        anim = this.GetComponent<Animation>();
        if(anim)
        {
            endClipName = anim.clip.name;
        }
        //Begin();

    }
	
	// Update is called once per frame
	void Update () {

    }
    public void Begin()
    {
        if (string.IsNullOrEmpty(startClipName) || string.IsNullOrEmpty(endClipName))
        {
            Loong.Game.iTrace.eError("hs", "传入的动画为Ϊnil");
            return;
        }
        scn = anim[startClipName].clip;
        if (scn)
        {
            AddAnimationEvent(scn.length);
        }
        anim.Play(startClipName);
    }
    public void AddAnimationEvent(float time)
    {
        //创建动画事件
        AnimationEvent animationEvent = new AnimationEvent();
        //设置事件回掉函数名字
        animationEvent.functionName = "OnEventHandler";
        //传入参数
        //animationEvent.objectReferenceParameter = target;
        //设置触发帧
        animationEvent.time = time;
        //注册事件
        scn.AddEvent(animationEvent);
    }

    public void OnEventHandler()
    {
        if (anim == null) return;
        if (isCrossFade)
            anim.CrossFade(endClipName, cfTime);
        else
            anim.Play(endClipName);
    }
}
