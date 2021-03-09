using UnityEngine;
using System.Collections.Generic;
using Loong.Game;

public class GameEventManager
{
    public static readonly GameEventManager instance = new GameEventManager();

    private GameEventManager()
    {

    }

    List<GameEvent> mGameEvents = new List<GameEvent>();
    int mCursor = 0;
    int mMaxCursor = 50;  //缓存事件总数量
    int mCursorPerFrame = 5;  //每帧运行事件个数

    public void Initialize()
    {
        EventMgr.Add(EventKey.BegChgScene, ChangeScene);
    }

    public void Update()
    {
        for (int i = 0; i < mCursorPerFrame; i++)
        {
            if (mGameEvents.Count == 0)
                continue;

            if (mCursor < mGameEvents.Count)
                mGameEvents[mCursor++].Execute();

            if (mCursor >= mGameEvents.Count)
            {
                mGameEvents.Clear();
                mCursor = 0;
            }
        }
    }

    public void Reset()
    {
        mGameEvents.Clear();
        mCursor = 0;
    }

    public void DestroyEffect(GameObject go)
    {
        if (go == null)
            return;
        ShowEffectMgr.instance.RemoveShowEffect(go);
        ParticleSystem[] parts = go.GetComponentsInChildren<ParticleSystem>();
        for (int i = 0; i < parts.Length; i++ )
            parts[i].Clear();
        if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneDone)
            ShowEffectMgr.instance.AddToPool(go);
        else
            GameObject.Destroy(go);
    }

    public void DelayDestroyCallback(GameObject go, long unitUID)
    {
        DestroyEffect(go);
        Unit unit = UnitMgr.instance.FindUnitByUid(unitUID);
        if (unit == null) return;
        unit.mUnitEffects.RemoveEffect(go);
    }
    
    public void EnQueue(GameEvent gameEvent, bool insert)
    {
        if (Global.Main == null)
        {
            gameEvent.Execute();
            return;
        }

        if (gameEvent.CanIgnore && mGameEvents.Count > mMaxCursor)
            return;

        if (insert)
        {
            if (mCursor > 0)
                mGameEvents[--mCursor] = gameEvent;
            else
                mGameEvents.Insert(0, gameEvent);
        }
        else
            mGameEvents.Add(gameEvent);
    }

    public void EnQueue(GameEvent gameEvent)
    {
        EnQueue(gameEvent, false);
    }

    public void ChangeScene(params object[] agrs)
    {
        Reset();
    }
}
