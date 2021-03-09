using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class DropEffect
{
    public UIPlayTween playTween;
    public TweenPosition tp;

    private Vector3 mPos = Vector3.zero;

    public void Init(Vector3 pos)
    {
        this.mPos = pos;

        AssetMgr.LoadPrefab("UI_Drop", LoadCall);
    }
    public void LoadCall(GameObject go)
    {
        if (go == null)
        {
            Debug.Log("加载特效特效特效为空");
            return;
        }
        go.transform.parent = GameObject.Find("UI Root").transform;
        go.transform.localScale = Vector3.one;
        go.SetActive(false);
        go.SetActive(true);

        //世界-----》屏幕
        Vector3 startPos = mPos;
        startPos.Set(startPos.x, startPos.y, 0);
        Vector3 screenPos = Camera.main.WorldToScreenPoint(startPos);
        screenPos.Set(screenPos.x, screenPos.y, 0);
        //屏幕-----》NGUI
        Vector3 pos = UICamera.currentCamera.ScreenToWorldPoint(screenPos);
        pos.Set(pos.x, pos.y, 0);
        playTween = go.transform.GetComponent<UIPlayTween>();
        if (playTween == null) Debug.LogError("playtween==null");
        tp = go.transform.GetComponent<TweenPosition>();
        if (tp == null) Debug.LogError("tp==null");
        go.transform.localPosition = pos;
        Debug.Log("POS: " + go.transform.localPosition);
        tp.worldSpace = false;
        tp.from = pos;

        EventDelegate.Add(tp.onFinished, OnFinsh);
        playTween.Play(true);
    }

    public  void OnFinsh()
    {
        if (tp == null)
        {
            Debug.LogError("tp==null");
            return;
        }
        if (playTween == null)
        {
            Debug.LogError("playTween == null");
            return;
        }
        tp.onFinished.Clear();
        ShowEffectMgr.instance.AddToPool(playTween.transform.gameObject);
        ObjPool.Instance.Add(this);
        playTween = null;
        tp = null;
    }
}
