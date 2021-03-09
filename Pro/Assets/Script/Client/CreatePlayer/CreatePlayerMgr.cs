using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CreatePlayerMgr
{
    public static readonly CreatePlayerMgr instance = new CreatePlayerMgr();

    private GameObject InitGo;
    private Vector3 InitPos;
    private GameObject MaleGo;
    private GameObject FemaleGo;
    private Vector3 MalePos;
    private Vector3 FemalePos;

    private UIPlayTween PlayTween;
    private TweenPosition TweenPosition;
    private UnitUIAnimEvent CurEvent;

    public void Init()
    {
        InitGo = GameObject.Find("InitGameObject");
        if(InitGo != null)
        {
            InitPos = InitGo.transform.position;
            //CameraMgr.UpdateOperation(CameraType.Player, InitGo.transform);
            InitTween();
        }
        MaleGo = GameObject.Find("P_Male01");
        if (MaleGo != null)
        {
            MalePos = MaleGo.transform.position;
        }
        FemaleGo = GameObject.Find("P_Female01");
        if (FemaleGo != null)
        {
            FemalePos = FemaleGo.transform.position;
        }
        InitEvent();
    }

    private void InitTween()
    {
        if (InitGo == null) return;
        PlayTween = InitGo.AddComponent<UIPlayTween>();
        if (PlayTween)
        {
            PlayTween.includeChildren = true;
            PlayTween.tweenGroup = 9;
            PlayTween.trigger = AnimationOrTween.Trigger.OnActivate;
        }
        TweenPosition = InitGo.AddComponent<TweenPosition>();
        if (TweenPosition)
        {
            TweenPosition.enabled = false;
            Vector3 pos = InitPos;
            TweenPosition.from = pos;
            TweenPosition.tweenGroup = 9;
            TweenPosition.duration = 0.5f;
        }
    }

    private void InitEvent()
    {
        EventMgr.Add(EventKey.OnSelectPlayer, SelectPlayerHandler);
        EventMgr.Add(EventKey.OnRestoreSelectPlayer, RestoreSelectPlayerHandler);
    }

    private void RemoveEvent()
    {
        EventMgr.Remove(EventKey.OnSelectPlayer, SelectPlayerHandler);
        EventMgr.Remove(EventKey.OnRestoreSelectPlayer, RestoreSelectPlayerHandler);
    }

    private void SelectPlayerHandler(params object[] objs)
    {
        if (objs == null || objs.Length == 0) return;
        bool isMale = (bool)objs[0];
        float offset = 0.0f;
        if (isMale)
        {
            offset = MalePos.x;
            CurEvent = MaleGo.GetComponent<UnitUIAnimEvent>();
        }
        else
        {
            offset = FemalePos.x;
            CurEvent = FemaleGo.GetComponent<UnitUIAnimEvent>();
        }
        if(TweenPosition)
        {
            Vector3 target = TweenPosition.from;
            target.x = offset;
            TweenPosition.to = target;
        }
        if(PlayTween)
        {
            PlayTween.Play(true);
            EventMgr.Trigger(EventKey.OnMoveUISelectPlayer, true);
        }
        if (CurEvent != null)
        {
            CurEvent.Begin();
        }
    }

    private void RestoreSelectPlayerHandler(params object[] objs)
    {
        if (PlayTween)
        {
            PlayTween.Play(false);
            EventMgr.Trigger(EventKey.OnMoveUISelectPlayer, false);
        }
    }

    public void Dispose()
    {
        RemoveEvent();
    }
}
