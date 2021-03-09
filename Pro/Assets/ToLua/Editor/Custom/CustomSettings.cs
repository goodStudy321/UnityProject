using System;
using Phantom;
using Phantom.Protocal;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

using BindType = ToLuaMenu.BindType;
using System.Reflection;
using UnityEditor;
using UnityEngine.Networking;

public static class CustomSettings
{
    public static string saveDir = Application.dataPath + "/Source/Generate/";
    public static string toluaBaseType = Application.dataPath + "/ToLua/BaseType/";
    public static string baseLuaDir = Application.dataPath + "/Tolua/Lua/";
    public static string injectionFilesPath = Application.dataPath + "/ToLua/Injection/";

    //导出时强制做为静态类的类型(注意customTypeList 还要添加这个类型才能导出)
    //unity 有些类作为sealed class, 其实完全等价于静态类
    public static List<Type> staticClassTypes = new List<Type>
    {
        typeof(UnityEngine.Application),
        typeof(UnityEngine.Time),
        typeof(UnityEngine.Screen),
        typeof(UnityEngine.SleepTimeout),
        typeof(UnityEngine.Input),
        typeof(UnityEngine.Resources),
        typeof(UnityEngine.Physics),
        typeof(UnityEngine.RenderSettings),
        typeof(UnityEngine.QualitySettings),
        typeof(UnityEngine.GL),
        typeof(UnityEngine.Graphics),
    };

    //附加导出委托类型(在导出委托时, customTypeList 中牵扯的委托类型都会导出， 无需写在这里)
    public static DelegateType[] customDelegateList =
    {
        _DT(typeof(Action)),
        _DT(typeof(UnityEngine.Events.UnityAction)),
        _DT(typeof(System.Predicate<int>)),
        _DT(typeof(System.Action<int>)),
        _DT(typeof(System.Comparison<int>)),
        _DT(typeof(System.Action<UnityEngine.Object>)),

    };

    //在这里添加你要导出注册到lua的类型列表
    public static BindType[] customTypeList =
    {
        //------------------------为例子导出--------------------------------
        //_GT(typeof(TestEventListener)),
        //_GT(typeof(TestProtol)),
        //_GT(typeof(TestAccount)),
        //_GT(typeof(Dictionary<int, TestAccount>)).SetLibName("AccountMap"),
        //_GT(typeof(KeyValuePair<int, TestAccount>)),    
        //_GT(typeof(TestExport)),
        //_GT(typeof(TestExport.Space)),
        //-------------------------------------------------------------------   



#if LUA_DEBUG
        _GT(typeof(LuaDebugTool)),
        _GT(typeof(LuaValueInfo)),    
#endif
        _GT(typeof(LuaInjectionStation)),
        _GT(typeof(InjectType)),
        _GT(typeof(Debugger)).SetNameSpace(null),        

#if USING_DOTWEENING
        _GT(typeof(DG.Tweening.DOTween)),
        _GT(typeof(DG.Tweening.Tween)).SetBaseType(typeof(System.Object)).AddExtendType(typeof(DG.Tweening.TweenExtensions)),
        _GT(typeof(DG.Tweening.Sequence)).AddExtendType(typeof(DG.Tweening.TweenSettingsExtensions)),
        _GT(typeof(DG.Tweening.Tweener)).AddExtendType(typeof(DG.Tweening.TweenSettingsExtensions)),
        _GT(typeof(DG.Tweening.LoopType)),
        _GT(typeof(DG.Tweening.PathMode)),
        _GT(typeof(DG.Tweening.PathType)),
        _GT(typeof(DG.Tweening.RotateMode)),
        _GT(typeof(Component)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(Transform)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(Light)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(Material)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(Rigidbody)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(Camera)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        _GT(typeof(AudioSource)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        //_GT(typeof(LineRenderer)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),
        //_GT(typeof(TrailRenderer)).AddExtendType(typeof(DG.Tweening.ShortcutExtensions)),    
#else
                                         
        _GT(typeof(Component)),
        _GT(typeof(Transform)),
        _GT(typeof(Material)),
        _GT(typeof(Light)),
        _GT(typeof(Rigidbody)),
        _GT(typeof(Camera)),
        _GT(typeof(AudioSource)),
        //_GT(typeof(LineRenderer))
        _GT(typeof(TrailRenderer)),
#endif

        _GT<Sdk>(),
        _GT<DeviceBase>(),
        _GT<Device>(),

        _GT(typeof(App)),
        _GT(typeof(DateTime)),
        _GT(typeof(TimeSpan)),
        _GT(typeof(DayOfWeek)),

        _GT(typeof(Behaviour)),
        _GT(typeof(MonoBehaviour)),
        _GT(typeof(GameObject)),
        _GT(typeof(TrackedReference)),
        _GT(typeof(Application)),
        _GT(typeof(Physics)),
        _GT(typeof(Collider)),
        _GT(typeof(Time)),
        _GT(typeof(Texture)),
        _GT(typeof(Texture2D)),
        _GT(typeof(Shader)),
        _GT(typeof(Renderer)),
        _GT(typeof(UnityWebRequest)),
        _GT(typeof(DownloadHandlerTexture)),
        _GT(typeof(DownloadHandlerBuffer)),

        
        _GT(typeof(WWWForm)),
        _GT(typeof(Screen)),
        _GT(typeof(CameraClearFlags)),
        _GT(typeof(AudioClip)),
        _GT(typeof(AssetBundle)),
        _GT(typeof(ParticleSystem)),
        _GT(typeof(AsyncOperation)),
        _GT(typeof(LightType)),
        _GT(typeof(SleepTimeout)),
#if UNITY_5_3_OR_NEWER && !UNITY_5_6_OR_NEWER
        _GT(typeof(UnityEngine.Experimental.Director.DirectorPlayer)),
#endif
        _GT(typeof(Animator)),
        _GT(typeof(Input)),
        _GT(typeof(KeyCode)),
        _GT(typeof(SkinnedMeshRenderer)),
        _GT<ParticleSystemRenderer>(),
        _GT(typeof(Space)),
        _GT(typeof(SendMessageOptions)),

        _GT(typeof(MeshRenderer)),
#if !UNITY_5_4_OR_NEWER
        _GT(typeof(ParticleEmitter)),
        _GT(typeof(ParticleRenderer)),
        _GT(typeof(ParticleAnimator)), 
#endif

#if UNITY_ANDROID
        _GT<Activity>(),
        _GT<AndroidPush>(),
#elif UNITY_IOS
        _GT<iOSPush>(),
#endif
        
        _GT(typeof(BoxCollider)),
        _GT(typeof(MeshCollider)),
        _GT(typeof(SphereCollider)),
        _GT(typeof(CharacterController)),
        _GT(typeof(CapsuleCollider)),

        _GT(typeof(Animation)),
        _GT(typeof(AnimationClip)).SetBaseType(typeof(UnityEngine.Object)),
        _GT(typeof(AnimationState)),
        _GT(typeof(AnimationBlendMode)),
        _GT(typeof(QueueMode)),
        _GT(typeof(PlayMode)),
        _GT(typeof(WrapMode)),

        _GT(typeof(QualitySettings)),
        _GT(typeof(RenderSettings)),
        _GT(typeof(SkinWeights)),
        _GT(typeof(RenderTexture)),
        _GT(typeof(Resources)),

        _GT<PoolBase<GameObject>>(),
        _GT<GbjPool>(),
        _GT<AssetLoadBase>(),
        _GT<PlayerPrefs>(),
#if LOONG_AB_SYNC
        _GT<AssetLoadSync>(),
#if UNITY_EDITOR
        _GT<AssetLoadRes>(),
#endif
#else
        _GT<AssetLoadAsync>(),
#endif
        _GT<UnityEngine.Video.VideoClip>(),
        _GT<UnityEngine.Video.VideoPlayer>(),
        _GT(typeof(UnityEngine.Video.VideoAspectRatio)),
        _GT(typeof(AssetMgr)),
        _GT<GameSceneManager>(),
        _GT<GameSceneBase>(),
        _GT<SceneManager>(),
        _GT<Scene>(),
        _GT<LoadSceneMode>(),
        _GT<HangupMgr>(),
        _GT<ParticleSystemMgr>(),
        _GT(typeof(Sound)),
        _GT(typeof(Audio)),
        _GT(typeof(Music)),
        _GT(typeof(EventMgr)),
        _GT(typeof(NetworkMgr)),
        _GT<NetFightInfo>(),
        _GT(typeof(User)),
        _GT(typeof(JoyStickCtrl)),
        _GT(typeof(NPCMgr)),
        _GT(typeof(DialogInfo)),
        _GT(typeof(List<DialogInfo>)),
        _GT(typeof(GMManager)),
        _GT<UnitUIModel>(),
        _GT<ActorData>(),
        _GT<EventDelegate>(),
        _GT(typeof(List<EventDelegate>)),
        _GT(typeof(TimeTool)),
         _GT(typeof(ErrorCodeMgr)),
         _GT(typeof(Utility)),
         _GT(typeof(NetRevive)),
         _GT(typeof(FlowChartMgr)),
         _GT(typeof(NetWorldBoss)),
         _GT(typeof(DelayDestroy)),
         _GT(typeof(UIEffectBinding)),
         _GT(typeof(UIEffBinding)),
         _GT(typeof(UIMenuTip)),
         _GT(typeof(UIRotateMod)),
         _GT(typeof(LuaNetBridge)),
         _GT(typeof(FindHelper)),
         _GT(typeof(UnitUIAnimEvent)),
         _GT(typeof(UnitFrMove)),
         _GT(typeof(MapHelper)),
         _GT(typeof(QualityMgr)),
         _GT(typeof(PTLuaInfo)),
         _GT(typeof(List<PTLuaInfo>)),
         _GT(typeof(BossKillMgr)),
         _GT(typeof(RapidBlurEffectTexture)),
         _GT(typeof(UIFly)),
         _GT(typeof(UIFlyAlpha)),
         _GT(typeof(UIFlyScale)),
         _GT(typeof(UICustomPopupList)),
         _GT(typeof(SelectRoleMgr)),
         _GT(typeof(WwwTool)),
         _GT(typeof(List<UIFly>)),
         _GT(typeof(List<UIFlyAlpha>)),
         _GT(typeof(List<UIFlyScale>)),
         _GT(typeof(EmoMgr)),
         _GT(typeof(MoveAroundPoint)),
         _GT(typeof(MobileMedia)),
         _GT(typeof(System.IO.File)),
         _GT(typeof(UnityEngine.TextureFormat)),
         _GT(typeof(guiraffe.SubstanceOrb.OrbAnimator)),
         _GT(typeof(ChatVoiceMgr)),
         _GT(typeof(EndPoint)),
         _GT(typeof(AwakenPortalFig)),
         _GT(typeof(Unit)),
         _GT(typeof(ArcSV)),
         _GT(typeof(BossBatMgr)),
         _GT(typeof(UIScrollBar)),
         _GT(typeof(DropMgr)),
         _GT(typeof(SaveTexPath)),
         _GT(typeof(DownloadHandler)),

         
#region 常用列表
         _GT(typeof(List<Vector3>)),
         _GT(typeof(List<string>)),
         _GT(typeof(List<int>)),
         _GT(typeof(List<long>)),
         _GT(typeof(Dictionary<string,int>)),
         _GT(typeof(Dictionary<int,int>)),
         _GT(typeof(List<Transform>)),
#endregion
        //配置表文件
        _GT<Table.Binary>(),
        _GT(typeof(Table.Manager<MissionInfo>)),
        _GT<MissionInfo>(),
        _GT<MissionInfo.param>(),
        _GT(typeof(List<MissionInfo.data>)),
        _GT<MissionInfo.data>(),
        _GT(typeof(List<MissionInfo.reward>)),
        _GT<MissionInfo.reward>(),
        _GT(typeof(MissionInfoManager)),
        _GT(typeof(NPCInfoManager)),
        _GT(typeof(Table.Manager<NPCInfo>)),
        _GT<NPCInfo>(),
        _GT<NPCInfo.vector3>(),
        _GT<NPCInfo.data>(),
        _GT(typeof(GlobalDataManager)),
        _GT(typeof(Table.Manager<GlobalData>)),
        _GT<GlobalData>(),
        _GT<SceneInfo>(),
        _GT<UnitFollow>(),
        _GT(typeof(CutscenePlayMgr)),
        _GT<Phantom.Protocal.p_kv>(),
        _GT(typeof(List<Phantom.Protocal.p_kv>)),
        _GT<Phantom.Protocal.p_skill>(),
        _GT(typeof(List<Phantom.Protocal.p_skill>)),

        //NGUI
        _GT<UIRoot>(),
        _GT<UIRect>(),
        _GT<UIRect.AnchorPoint>(),
        _GT<UIPanel>(),
        _GT<UIWidget>(),
        _GT<UIWidget.Pivot>(),
        _GT<UILabel>(),
        _GT<UIInput>(),
        _GT<UIButtonColor>(),
        _GT<UIButton>(),
        _GT<UIBasicSprite>(),
        _GT<UIProgressBar>(),
        _GT<UIWidgetContainer>(),
        _GT<UISprite>(),
        _GT<UISlider>(),
        _GT<UITexture>(),
        _GT<UIEventListener>(),
        _GT<UIPopupList>(),
        _GT<UIToggle>(),
        _GT<UIGrid>(),
        _GT<UITable>(),
        _GT<UICenterOnChild>(),
        _GT<SpringPanel>(),
        _GT<SpringPosition>(),
        _GT<UITweener>(),
        _GT<TweenAlpha>(),
        _GT<TweenScale>(),
        _GT<TweenPosition>(),
        _GT<UIPlayTween>(),
        _GT<UIScrollView>(),
        _GT<UIWrapContent>(),
        _GT<UISpriteData>(),
        _GT<UIAtlas>(),
        _GT(typeof(List<UISpriteData>)),
        _GT<UICamera>(),
        _GT<TypewriterEffect>(),
        _GT<NGUIText.Alignment>(),
        _GT<UIButtonScale>(),
        _GT<UIBasicSprite.Type>(),
#if UNITY_EDITOR
        _GT(typeof(UnityEngine.Profiling.Profiler)),
#endif
    };

    public static List<Type> dynamicList = new List<Type>()
    {
        typeof(MeshRenderer),
#if !UNITY_5_4_OR_NEWER
        typeof(ParticleEmitter),
        typeof(ParticleRenderer),
        typeof(ParticleAnimator),
#endif

        typeof(BoxCollider),
        typeof(MeshCollider),
        typeof(SphereCollider),
        typeof(CharacterController),
        typeof(CapsuleCollider),

        typeof(Animation),
        typeof(AnimationClip),
        typeof(AnimationState),

        typeof(SkinWeights),
        typeof(RenderTexture),
        typeof(Rigidbody),
    };

    //ngui优化，下面的类没有派生类，可以作为sealed class
    public static List<Type> sealedList = new List<Type>()
    {
    };

    //重载函数，相同参数个数，相同位置out参数匹配出问题时, 需要强制匹配解决
    //使用方法参见例子14
    public static List<Type> outList = new List<Type>()
    {

    };

    public static BindType _GT(Type t)
    {
        return new BindType(t);
    }

    public static BindType _GT<T>()
    {
        return new BindType(typeof(T));
    }

    public static DelegateType _DT(Type t)
    {
        return new DelegateType(t);
    }

    public static DelegateType _DT<T>()
    {
        return new DelegateType(typeof(T));
    }

    [MenuItem("Lua/Attach Profiler", false, 151)]
    static void AttachProfiler()
    {
        if (!Application.isPlaying)
        {
            EditorUtility.DisplayDialog("警告", "请在运行时执行此功能", "确定");
            return;
        }

        LuaClient.Instance.AttachProfiler();
    }

    [MenuItem("Lua/Detach Profiler", false, 152)]
    static void DetachProfiler()
    {
        if (!Application.isPlaying)
        {
            return;
        }

        LuaClient.Instance.DetachProfiler();
    }
}
