using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Loong.Game;

public class AccMgr
{
    public static readonly AccMgr instance = new AccMgr();

    private const string Name = "Character_Create_01";

    #region 私有方法
    /// <summary>
    /// SDK登入成功回調
    /// </summary>
    private void LoginSucHandler(params object[] args)
    {
        //EnterLoginScene();
    }


    /// <summary>
    /// 登出回調
    /// </summary>
    private void LogoutSucHandler(params object[] args)
    {
        if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneLoading)
        {
            EventMgr.Add(EventKey.OnChangeScene, ChangeSceneEnd);
            MsgBox.Show(620012, 690000, null);
            return;
        }
         ReturnLoginScene();
    }

    /// <summary>
    /// 加載場景完成回調
    /// </summary>
    /// <param name="scene"></param>
    /// <param name="mode"></param>
    private void LoadSceneFinish(Scene scene, LoadSceneMode mode)
    {
        SceneTool.Switch(scene.name);
        SceneTool.onloaded -= LoadSceneFinish;
        EventMgr.Trigger(EventKey.OnEnterLogin);
        Global.Main.StartCoroutine(YieldOpenLogin());
    }

    private IEnumerator YieldOpenLogin()
    {
        yield return null;
        yield return null;
        UIMgr.Open(UIName.UILogin, null);
        
        SceneTool.Switch(Name);
#if UNITY_EDITOR
        yield return null;
        yield return null;
        ShaderTool.eResetSkybox();
#endif
    }

    private void ChangeSceneEnd(params object[] objs)
    {
        EventMgr.Remove(EventKey.OnChangeScene, ChangeSceneEnd);
        ReturnLoginScene();
    }
    #endregion

    #region 公开方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Initialize()
    {
        iTrace.eWarning("hs", "初始化accMgr, 註冊登出遊戲事件");
        EventMgr.Add("SdkSuc", LoginSucHandler);
        EventMgr.Add("LogoutSuc", LogoutSucHandler);
    }

    public void Logout()
    {
        EventMgr.Trigger("LogoutSuc");
    }

    /// <summary>
    /// 返回到登入界面
    /// </summary>
    public void ReturnLoginScene()
    {
        NetworkClient.Disconnect();
       
        Global.Main.StartCoroutine(YieldReturnLogin());

    }



    private IEnumerator YieldReturnLogin()
    {
        Scene scene = SceneManager.GetActiveScene();
        if (scene.name.Contains(Name))
        {
            HeartBeat.instance.Reset();
            Global.Main.StartCoroutine(YieldOpenLogin());
            iTrace.eLog("hs", "返回到登入界面，当前场景是需要进入的场景，不加载");
            yield break;
        }

        UIMgr.Open(UIName.UILoading, null);
        yield return null;
        yield return SceneTool.SwitchClear(Name);
        AssetMgr.Instance.AutoCloseIPro = true;
        GameSceneManager.instance.DisposeCurScene();
        HangupMgr.instance.ClearAutoInfo();
        DisposeTool.All();
        AssetMgr.Instance.Add(Name, ".unity", null);
        AssetMgr.Instance.LoadSceneCount = 1;
        AssetMgr.Instance.complete += EnterLoginScene;
        AssetMgr.Start();
        iTrace.eLog("hs", "登出遊戲 釋放數據 預加載場景資源");
    }


    /// <summary>
    /// 进入登入界面
    /// </summary>
    public void EnterLoginScene()
    {
        iTrace.eLog("hs", "加載登入場景，進入登入界面");
        AssetMgr.Instance.complete -= EnterLoginScene;
        EventMgr.Trigger(EventKey.CamClose);

        SceneTool.onloaded += LoadSceneFinish;
        SceneManager.LoadScene(Name, LoadSceneMode.Additive);
    }


    public void Unload()
    {
       Global.Main.StartCoroutine(SceneTool.Unload(Name));
    }

    #endregion
}
