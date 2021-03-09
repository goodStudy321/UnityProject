using System.IO;
using System.Text;
using UnityEngine;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Hello.Game
{
    public static class AssetPath
    {
        private static string data = null;
        private static string cache = null;
        private static string commen = null;
        private static string wwwCommen = null;
        private static string platform = null;
        private static string streaming = null;
        private static string wwwStreaming = null;
        private static string persistent = null;
        private static string wwwPersistent = null;
        private static string assetBundle = null;
        private static string wwwAssetBundle = null;
        private static bool existInPersistent = false;
        private static StringBuilder uri = new StringBuilder();

        /// <summary>
        /// 数据路径
        /// </summary>
        public static string Data { get { return data; } }
        /// <summary>
        /// 临时缓存路径
        /// </summary>
        public static string Cache { get { return cache; } }

        /// <summary>
        /// 通用路径
        /// </summary>
        public static string Commen { get { return commen; } }

        /// <summary>
        /// 通用路径/使用WWW
        /// </summary>
        public static string WwwCommen { get { return wwwCommen; } }

        /// <summary>
        /// 流文件夹路径
        /// </summary>
        public static string Streaming { get { return streaming; } }

        /// <summary>
        /// 流文件夹路径/使用WWW
        /// </summary>
        public static string WwwStreaming { get { return wwwStreaming; } }

        /// <summary>
        /// 持久化路径
        /// </summary>
        public static string Persistent { get { return persistent; } }

        /// <summary>
        /// 持久化路径/使用WWW
        /// </summary>
        public static string WwwPersistent { get { return wwwPersistent; } }

        /// <summary>
        /// 资源包路径
        /// </summary>
        public static string AssetBundle { get { return assetBundle; } }

        /// <summary>
        /// 资源包路径/使用WWW
        /// </summary>
        public static string WwwAssetBundle { get { return wwwAssetBundle; } }

        /// <summary>
        /// 持久化数据路径下是否存在资源
        /// </summary>
        public static bool ExistInPersistent { get { return existInPersistent; } }

        /// <summary>
        /// 当前平台字符
        /// </summary>
        public static string Platform { get { return platform; } }

#if UNITY_EDITOR

        /// <summary>
        /// 编辑器下资源输出目录
        /// </summary>
        public static string Output
        {
            get
            {
                string key = Path.GetFullPath("./iOutputFolder");
                string output = EditorPrefs.GetString(key);
                if (string.IsNullOrEmpty(output) || output[0] == '.') output = Path.GetFullPath("../Assets");
                return output;
            }
        }
#endif

        static AssetPath()
        {
            platform = GetPlatformFolder(Application.platform);
            data = Application.dataPath;
            cache = Application.temporaryCachePath + "/";
            streaming = Application.streamingAssetsPath;
            persistent = Application.persistentDataPath;
            wwwStreaming = GetStreamingWwwPath();
            wwwPersistent = GetPersitentWwwPath();
            Refresh();
        }

#if CS_HOTFIX_ENABLE
        private static string GetStreamingWwwPath()
        {
            if (Application.isEditor)
            {
                uri.Append("file:///").Append(Streaming);
            }
            else if (Application.platform == RuntimePlatform.Android)
            {
                uri.Append("jar:file://").Append(Data).Append("!/assets");
            }
            else if (Application.platform == RuntimePlatform.IPhonePlayer)
            {
                uri.Append("file://").Append(Data).Append("/Raw");
            }
            else
            {
                uri.Append("file:///").Append(Streaming);
            }
            uri.Append("/");
            string newUri = uri.ToString();
            uri.Remove(0, uri.Length);
            return newUri;
        }
#else
        private static string GetStreamingWwwPath()
        {
#if UNITY_EDITOR
            uri.Append("file:///").Append(Streaming);
#elif UNITY_ANDROID
            uri.Append("jar:file://").Append(Data).Append("!/assets");
#elif UNITY_IPHONE
            uri.Append("file://").Append(Data).Append("/Raw");
#else
            uri.Append("file:///").Append(Streaming);
#endif
            uri.Append("/");
            string newUri = uri.ToString();
            uri.Remove(0, uri.Length);
            return newUri;
        }
#endif
        /// <summary>
        /// 获取外部持久化资源路径
        /// </summary>
        private static string GetPersitentWwwPath()
        {
            uri.Append("file:///").Append(Persistent).Append("/");
            string newUri = uri.ToString();
            uri.Remove(0, uri.Length);
            return newUri;
        }

        /// <summary>
        /// 获取AssetBundle路径
        /// </summary>
        private static string GetAssetBundlePath(bool www)
        {
            if (www) uri.Append(WwwCommen);
            else uri.Append(Commen);
            uri.Append(Platform).Append("/");
            string newUri = uri.ToString();
            uri.Remove(0, uri.Length);
            return newUri;
        }

        private static void SetExistInPersistent()
        {
            string verPath = Persistent + "/AssetVer.txt";
            existInPersistent = (File.Exists(verPath)) ? true : false;
        }

        /// <summary>
        /// 获取通用资源路径
        /// </summary>
        /// <param name="www"></param>
        /// <returns></returns>
        public static string GetCommenPath(bool www)
        {
            if (ExistInPersistent)
            {
                if (www) return WwwPersistent;
                return string.Format("{0}/", Persistent);
            }
            else if (Application.isEditor)
            {
#if UNITY_EDITOR

                if (www) return string.Format("file:///{0}/", Output);
                else return string.Format("{0}/", Output);
#else
                return "";
#endif
            }
            else
            {
                if (www) return WwwStreaming;
                return string.Format("{0}/", Streaming);
            }
        }

        /// <summary>
        /// 刷新
        /// </summary>
        public static void Refresh()
        {
            SetExistInPersistent();
            commen = GetCommenPath(false);
            wwwCommen = GetCommenPath(true);
            assetBundle = GetAssetBundlePath(false);
            wwwAssetBundle = GetAssetBundlePath(true);

            if (App.IsDebug)
            {
                Debug.LogFormat("Hello", "Persist:{0}, Streaming:{1}", Persistent, Streaming);
            }
        }

        /// <summary>
        /// 获取各平台放置AB的特定文件夹
        /// </summary>
        public static string GetPlatformFolder(RuntimePlatform platform)
        {

#if UNITY_EDITOR
            return GetPlatformFolder(EditorUserBuildSettings.activeBuildTarget);
#else
            switch (platform)
            {
                case RuntimePlatform.Android:
                    return "Android";
                case RuntimePlatform.IPhonePlayer:
                    return "iOS";
                case RuntimePlatform.WindowsPlayer:
                    return "Windows";
                case RuntimePlatform.OSXPlayer:
                    return "OSX";
                default:
                    return "Android";
            }
#endif
        }

#if UNITY_EDITOR
        public static string GetPlatformFolder(BuildTarget buildTarget)
        {
            switch (buildTarget)
            {
                case BuildTarget.Android:
                    return "Android";
                case BuildTarget.iOS:
                    return "iOS";
                case BuildTarget.StandaloneWindows:
                case BuildTarget.StandaloneWindows64:
                    return "Windows";
                //case BuildTarget.StandaloneOSXIntel:
                //case BuildTarget.StandaloneOSXIntel64:
                case BuildTarget.StandaloneOSX:
                    return "OSX";
                default:
                    return null;
            }
        }
#endif
    }
}


