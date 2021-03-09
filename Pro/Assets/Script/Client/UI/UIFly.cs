using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UIFly : UIWidgetContainer
{
    public static Dictionary<string,List<UIFly>> dic = new Dictionary<string, List<UIFly>>();

    public static List<UIFly> GetList(string key)
    {
        if(dic.ContainsKey(key))
            return dic[key];
        return null;
    }

    public static UIFly AddGo(string key, GameObject go)
    {
        UIFly fly = go.GetComponent<UIFly>();
        if (fly)
        {
            Add(key, fly);
        }
        return fly;
    }

    public static void Add(string key, UIFly fly)
    {
        if(!dic.ContainsKey(key))
        {
            dic.Add(key, new List<UIFly>());
        }
        dic[key].Add(fly);
    }

    public static void Remove(string key, UIFly fly)
    {
        if(dic.ContainsKey(key))
        {
            int index = dic[key].IndexOf(fly);
            if (index == -1)
            {
                Loong.Game.iTrace.eError("hs", "fly is nil");
                return;
            }
            dic[key].RemoveAt(index);
            if (dic[key].Count == 0) dic.Remove(key);
        }
    }

    public static void Dispose(string key)
    {
        if (dic[key] == null) return;
        while(dic[key].Count > 0)
        {
            UIFly fly = dic[key][0];
            Remove(key, fly);
        }
        dic[key].Clear();
        dic[key] = null;
    }

    protected enum Status
    {
        Fly,
        End
    }

    protected Status CurStatus;

    public delegate void EndDelegate(GameObject go);
    public EndDelegate onEndEvent;

    protected UIWidget widget;
    protected Color color;

    protected Vector3 startPos;
    public Vector3 anchors1;
    public Vector3 anchors2;
    public Vector3 targetPos;

    public float time = 10;
    protected float lastTime = 0;
    protected float lastDelayTime = 0;
    public float endDelay = 0.0f;

    public bool isDestroy = true;

    public GameObject target;
    public string goName;

    void Awake()
    {
        goName = this.transform.name;
        startPos = this.transform.localPosition;
        if (target != null)
        {
            UpdateTargetPos(transform.position);
        }
        CustomAwake();
    }
    void OnEnable()
    {
        CurStatus = Status.Fly;
        lastTime = Time.realtimeSinceStartup;
        CustomEnable();
    }

    void OnDisable()
    {
        CustomDisable();
    }
        
    void Update ()
    {
        CustomUpdate();
	}

    protected virtual void CustomAwake()
    {
    }

    protected virtual void CustomEnable() { }

    protected virtual void CustomDisable() { }

    protected virtual void CustomUpdate()
    {
        if(CurStatus == Status.Fly)
        {
            ExecuteFly();
        }
        else
        {
            ExecuteEnd();
        }
    }

    protected virtual void ExecuteFly()
    {
        float cur = Time.realtimeSinceStartup;
        if (lastTime != 0)
        {
            float offset = cur - lastTime;
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

    protected void ExecuteEnd()
    {
        if (endDelay > 0)
        {
            if (lastDelayTime == 0)
            {
                lastDelayTime = Time.realtimeSinceStartup;
                return;
            }
            else
            {
                if (Time.realtimeSinceStartup - lastDelayTime < endDelay)
                {
                    return;
                }
            }
        }
        if (isDestroy)
        {
            Destroy(gameObject);
        }
        else
        {
            if (onEndEvent != null)
                onEndEvent(gameObject);
        }
        EventMgr.Trigger("FlyFinish", goName);
    }

    protected void GetComponent()
    {
        widget = gameObject.GetComponent<UIWidget>();
        if (widget) color = widget.color;
    }

    public void Play()
    {
        gameObject.SetActive(true);
    }

    public void UpdateTargetPos(Vector3 pos)
    {
        Camera cam = UIMgr.Cam;
        if (cam == null) return;
        Vector3 sP = cam.WorldToScreenPoint(pos);
        Vector3 tP = cam.WorldToScreenPoint(target.transform.position);
        Vector3 offset = tP - sP;
        targetPos = startPos + offset;
    }
}
