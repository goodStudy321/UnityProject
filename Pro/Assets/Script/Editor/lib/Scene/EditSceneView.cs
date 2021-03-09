/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2017/2/5 12:06:14
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using UnityEditor.SceneManagement;

namespace Loong.Edit
{
    /// <summary>
    /// 场景视图
    /// </summary>
    public class EditSceneView : EditViewBase
    {
        #region 字段

        [SerializeField]
        [HideInInspector]
        private string sceneName;
        [SerializeField]
        [HideInInspector]
        private string mainScenePath = "./Assets/Main.unity";

        /// <summary>
        /// 场景目录
        /// </summary>
        [NonSerialized]
        public List<string> sceneDirs = new List<string>();

        /// <summary>
        /// 基础目录
        /// </summary>
        [NonSerialized]
        public List<FolderInfo> basics = new List<FolderInfo>();

        /// <summary>
        /// 分类子目录
        /// </summary>
        [NonSerialized]
        public List<FolderInfo> childs = new List<FolderInfo>();

        /// <summary>
        /// 场景根目录文件夹名称
        /// </summary>
        public const string scene = "Scene";
        /// <summary>
        /// 共享场景资源文件夹名称
        /// </summary>
        public const string share = "Share";

        /// <summary>
        /// 不需要分类的资源文件夹
        /// </summary>
        public const string iNone = "iNone";

        /// <summary>
        /// 场景根目录前缀
        /// </summary>
        public const string prefix = "Assets/Scene/";

        /// <summary>
        ///  不需要分类的资源文件夹前缀
        /// </summary>
        public const string packPrefix = "Assets/Pkg";

        /// <summary>
        /// 共享场景目录前缀
        /// </summary>
        public const string sharePrefix = "Assets/Scene/Share";

        /// <summary>
        /// 分类目录字典,键为后缀名,值为对应目录
        /// </summary>
        public static readonly Dictionary<string, FolderInfo> dic = new Dictionary<string, FolderInfo>();
        #endregion
        #region 属性
        /// <summary>
        /// 主场景路径
        /// </summary>
        public string MainScenePath
        {
            get
            {
                string path = Path.GetFullPath(mainScenePath);
                path = AssetPathUtil.GetRelativePath(path);
                return path;
            }
        }
        /// <summary>
        /// 主场景完整路径
        /// </summary>
        public string MainSceneFullPath
        {
            get { return Path.GetFullPath(mainScenePath); }
        }
        #endregion

        #region 构造方法
        static EditSceneView()
        {
            SetDic();
        }
        #endregion

        #region 私有方法

        private static void SetDic()
        {
            dic.Clear();
            dic.Add(Suffix.Jpg, new FolderInfo("Tex", "jpg格式贴图", scene));
            dic.Add(Suffix.Png, new FolderInfo("Tex", "png格式贴图", scene));
            dic.Add(Suffix.Tga, new FolderInfo("Tex", "tga格式贴图", scene));
            dic.Add(Suffix.Psd, new FolderInfo("Tex", "psd格式贴图/不应该出现", scene));
            dic.Add(Suffix.Exr, new FolderInfo("Tex", "光照贴图/同名场景文件夹下", scene));

            dic.Add(Suffix.Shader, new FolderInfo("Shader", "着色器", scene));
            dic.Add(Suffix.Mat, new FolderInfo("Mat", "普通材质", scene));
            dic.Add(Suffix.PhysicMat, new FolderInfo("Mat", "物理材质", scene));
            dic.Add(Suffix.Fbx, new FolderInfo("Fbx", "3DMAX模型", scene));
            dic.Add(Suffix.Mb, new FolderInfo("Fbx", "MAYA模型", scene));

            dic.Add(Suffix.Prefab, new FolderInfo("Prb", "预制体", scene));
            dic.Add(Suffix.Animation, new FolderInfo("Anim", "动画剪辑", scene));
            dic.Add(Suffix.Animator, new FolderInfo("Anim", "动画控制器", scene));
            dic.Add(Suffix.AvatarMask, new FolderInfo("Anim", "动画遮罩", scene));

            dic.Add(Suffix.Wav, new FolderInfo("Audio", "wav格式音效", scene));
            dic.Add(Suffix.Mp3, new FolderInfo("Audio", "mp3格式音效", scene));
            dic.Add(Suffix.Ogg, new FolderInfo("Audio", "mp3格式音效", scene));

            dic.Add(Suffix.Font, new FolderInfo("Font", "字体设置", scene));
            dic.Add(Suffix.OTF, new FolderInfo("Font", "OTF字体", scene));
            dic.Add(Suffix.TTF, new FolderInfo("Font", "TTF字体", scene));

            dic.Add(Suffix.Txt, new FolderInfo("Text", "纯文本", scene));
            dic.Add(Suffix.Json, new FolderInfo("Text", "Json文本", scene));
            dic.Add(Suffix.Xml, new FolderInfo("Text", "Xml文本", scene));

            dic.Add(Suffix.GUISkin, new FolderInfo("GUISkin", "GUI皮肤", scene));
            dic.Add(Suffix.Scene, new FolderInfo("Unity", "场景", scene));
            dic.Add(Suffix.Asset, new FolderInfo("Asset", "自定义资源", scene));
            dic.Add(Suffix.None, new FolderInfo(iNone, "不需要分类资源,如NGUI制作的Atlas和Font", scene));
        }

        private void SetSceneDirs()
        {
            sceneDirs.Clear();
            string curDir = Directory.GetCurrentDirectory();
            string sceneRootDir = string.Format("{0}/{1}", curDir, prefix);
            DirectoryInfo root = new DirectoryInfo(sceneRootDir);
            DirectoryInfo[] dirs = root.GetDirectories();
            if (dirs == null) return;
            int length = dirs.Length;
            for (int i = 0; i < length; i++)
            {
                string sceneDir = dirs[i].Name;
                sceneDir = string.Format("{0}{1}", prefix, sceneDir);
                sceneDirs.Add(sceneDir);
            }
        }

        /// <summary>
        /// 显示主场景设置
        /// </summary>
        private void SetMainScene()
        {
            if (!UIEditTool.DrawHeader("基础属性", "SceneBasicProperty", StyleTool.Host)) return;
            UIEditLayout.SetPath("主场景路径:", ref mainScenePath, this, "unity");
        }

        /// <summary>
        /// 显示基础文件夹的信息
        /// </summary>
        private void DrawBasicFolderInfo()
        {
            if (!UIEditTool.DrawHeader("基础文件夹信息", "basicFolderInfo", StyleTool.Host)) return;
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            EditorGUILayout.BeginVertical();

            int length = basics.Count;
            for (int i = 0; i < length; i++)
            {
                FolderInfo info = basics[i];
                EditorGUILayout.BeginHorizontal(StyleTool.Group);
                EditorGUILayout.LabelField(info.folder, GUILayout.Width(160));
                EditorGUILayout.LabelField(info.info, GUILayout.Width(160));
                if (Directory.Exists(info.fullPath))
                {
                    EditorGUILayout.LabelField("已存在", GUILayout.Width(100));
                }
                else
                {
                    EditorGUILayout.LabelField("未创建", GUILayout.Width(100));

                }
                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndVertical();
            if (GUILayout.Button("一键创建", GUILayout.Width(100)))
            {
                CreateBasicFolder();
                Event.current.Use();
            }
            EditorGUILayout.EndHorizontal();
        }
        /// <summary>
        /// 创建所有基础文件夹
        /// </summary>
        private void CreateBasicFolder()
        {
            if (basics == null) return;
            bool allExist = true;
            int length = basics.Count;
            for (int i = 0; i < length; i++)
            {
                if (!Directory.Exists(basics[i].fullPath))
                {
                    allExist = false;
                    Directory.CreateDirectory(basics[i].fullPath);
                }
            }
            if (allExist) ShowTip("全部存在,无需创建");
            else ShowTip("创建成功");
            AssetDatabase.Refresh();
        }


        private void DrawSceneFolderInfo()
        {
            if (!UIEditTool.DrawHeader("资源文件夹信息", "assetFolderInfo", StyleTool.Host)) return;
            if (childs.Count == 0) return;
            EditorGUILayout.BeginVertical(StyleTool.Box);
            EditorGUILayout.HelpBox("场景文件夹的根目录为Assets/Scene/场景名称,其包含的子文件夹信息如下:", MessageType.Info);
            for (int i = 0; i < childs.Count; i++)
            {
                FolderInfo info = childs[i];
                EditorGUILayout.BeginHorizontal(StyleTool.Group);
                EditorGUILayout.LabelField(info.folder, GUILayout.Width(160));
                EditorGUILayout.LabelField(info.info);
                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndVertical();
        }

        private void DrawCreateScene()
        {
            if (!UIEditTool.DrawHeader("创建具有标准资源文件夹的场景", "createStandardScene", StyleTool.Host)) return;
            UIEditLayout.HelpInfo(string.Format("无分类根目录:{0}", packPrefix));
            UIEditLayout.HelpInfo(string.Format("分类根目录:{0},并且以场景为单位进行区分", prefix));
            UIEditLayout.HelpWaring("如果创建完成后出现OnGUI的错误,不用理会");
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            EditorGUILayout.LabelField("输入场景名称:", GUILayout.Width(150));
            UIEditLayout.TextField("", ref sceneName, this);
            if (GUILayout.Button("创建标准场景目录"))
            {
                CreateScene(sceneName, this);
            }
            else if (GUILayout.Button("创建共享场景目录"))
            {
                CreateScene(share, this);
            }
            else if (GUILayout.Button("创建无分类目录"))
            {
                CreateNone();
            }
            EditorGUILayout.EndHorizontal();
        }


        private void DrawSceneFolder()
        {
            if (!UIEditTool.DrawHeader("场景文件夹信息", "sceneFolderInfo", StyleTool.Host)) return;
            if (sceneDirs.Count == 0) return;
            EditorGUILayout.BeginVertical(StyleTool.Box);
            for (int i = 0; i < sceneDirs.Count; i++)
            {
                string sceneDir = sceneDirs[i];
                EditorGUILayout.BeginHorizontal(StyleTool.Group);
                EditorGUILayout.LabelField("场景:", sceneDir);
                if (GUILayout.Button("打开", GUILayout.Width(60)))
                {
                    OpenScene(sceneDir);
                }
                else if (GUILayout.Button("定位", GUILayout.Width(60)))
                {
                    string sceneName = Path.GetFileName(sceneDir);
                    SceneMgr.Ping(sceneName);
                }
                EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndVertical();
        }


        private void OpenScene(string sceneDir)
        {
            string sceneName = sceneDir.Replace(prefix, "");
            StringBuilder sb = new StringBuilder();

            sb.Append(sceneDir).Append("/");
            sb.Append(dic[Suffix.Scene].folder).Append("/");
            sb.Append(sceneName).Append(Suffix.Scene);
            string scenePath = sb.ToString();
            sb.Remove(0, sb.Length);
            sb.Append(Directory.GetCurrentDirectory());
            sb.Append("/").Append(scenePath);
            string fullPath = sb.ToString();
            if (!File.Exists(fullPath))
            { ShowTip(string.Format("场景不存在:{0},{1}", sceneName, fullPath)); return; }
            if (EditorSceneManager.SaveCurrentModifiedScenesIfUserWantsTo())
            {
                ShowTip(string.Format("打开成功:{0}", scenePath));
                EditorSceneManager.OpenScene(scenePath);
            }
            else
            {
                ShowTip("已取消");
            }
        }

        private void SetBasic()
        {
            basics.Clear();
            basics.Add(new FolderInfo("Resources", "资源目录"));
            basics.Add(new FolderInfo("Plugins/Editor", "编辑器插件"));
            basics.Add(new FolderInfo("Plugins/Android", "安卓插件"));
            basics.Add(new FolderInfo("Plugins/iOS", "IOS插件"));
            basics.Add(new FolderInfo("Plugins/Standalone", "PC插件"));
            basics.Add(new FolderInfo("Script/Editor", "编辑器脚本"));
            basics.Add(new FolderInfo("Script/Client", "客户端脚本"));
            basics.Add(new FolderInfo("Gizmos", "编辑器图标"));
            basics.Add(new FolderInfo("ActionScript", "flash脚本"));
            basics.Add(new FolderInfo("WebPlayerTempllates", "网页游戏模板"));
            basics.Add(new FolderInfo("StreamingAssets", "流文件夹"));
        }

        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            SetMainScene();
            EditorGUILayout.Space();
            DrawBasicFolderInfo();
            EditorGUILayout.Space();
            DrawSceneFolderInfo();
            EditorGUILayout.Space();
            DrawCreateScene();
            EditorGUILayout.Space();
            DrawSceneFolder();
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public override void Initialize()
        {
            SetBasic();
            SetChilds();
            SetSceneDirs();
        }

        /// <summary>
        /// 设置分类目录
        /// </summary>
        public void SetChilds()
        {
            childs.Clear();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                childs.Add(em.Current.Value);
            }
        }

        /// <summary>
        /// 创建无分类目录
        /// </summary>
        public static void CreateNone()
        {
            string curDir = Directory.GetCurrentDirectory();
            string noneDir = string.Format("{0}/{1}", curDir, packPrefix);
            if (Directory.Exists(noneDir))
            {
                UIEditTip.Warning("已存在");
            }
            else
            {
                Directory.CreateDirectory(noneDir);
                AssetDatabase.Refresh();
                UIEditTip.Log("已创建");
            }
        }

        /// <summary>
        /// 创建共享场景
        /// </summary>
        public static void CreateShare()
        {
            string curDir = Directory.GetCurrentDirectory();
            string sceneShareDir = string.Format("{0}/{1}", curDir, sharePrefix);
            if (!Directory.Exists(sceneShareDir))
            {
                Directory.CreateDirectory(sceneShareDir);
                CreateScene(share);
            }

        }

        /// <summary>
        /// 创建场景文件夹
        /// </summary>
        /// <param name="sceneName">场景名称</param>
        /// <param name="view">设置数据</param>
        public static void CreateScene(string sceneName, EditSceneView view = null)
        {
            if (string.IsNullOrEmpty(sceneName))
            {
                UIEditTip.Error("场景名称为空"); return;
            }
            if (view != null)
            {
                if (!view.sceneDirs.Contains(sceneName))
                {
                    view.sceneDirs.Add(sceneName);
                    view.Win.Repaint();
                }
            }

            var sb = new StringBuilder();
            sb.Append(AssetPathUtil.CurDir).Append(prefix);
            sb.Append("/").Append(sceneName).Append("/");
            string preDir = sb.ToString();
            sb.Remove(0, sb.Length);
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current.Value;
                string fullDir = preDir + it.folder;
                sb.Append(it.folder);

                if (!Directory.Exists(fullDir))
                {
                    Directory.CreateDirectory(fullDir);
                    sb.Append(" 创建成功\n");
                }
                else
                {
                    sb.Append(" 已经存在\n");
                }

            }
            UIEditTip.Warning(sb.ToString());
            if (sceneName == share) return;
            SceneMgr.Create(sceneName);
        }

        /// <summary>
        /// 判断资源路径是否在分类根目录或者在不分类根目录中
        /// </summary>
        /// <param name="assetPath"></param>
        /// <returns></returns>
        public static bool Contains(string assetPath)
        {
            if (assetPath.StartsWith(packPrefix)) return true;
            if (assetPath.StartsWith(prefix)) return true;
            return false;
        }

        #endregion
    }
}