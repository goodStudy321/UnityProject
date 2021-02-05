//#define LOG_RES

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine.Networking;

using Hello.Game;

#if UNITY_EDITOR
using UnityEditor;
#endif

public class FileLoader
{
    public static readonly FileLoader instance = new FileLoader();

    /// <summary>
    /// 所在目录名
    /// </summary>
    public const string Home = "table";

    private FileLoader()
    {

    }
    private IProgress ipro;

    /// <summary>
    /// 进度接口
    /// </summary>
    public IProgress Ipro
    {
        get { return ipro; }
        set { ipro = value; }
    }

    /// <summary>
    /// 读取路径前缀
    /// </summary>
    private string m_url_prefix = string.Empty;
    /// <summary>
    /// 已经读取的table字典
    /// </summary>
    private Dictionary<string, byte[]> cacheTableData = new Dictionary<string, byte[]>();


    public void CheckPrefixUrl()
    {
#if UNITY_EDITOR
        if (!string.IsNullOrEmpty(m_url_prefix))
            return;

        if (Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.WindowsEditor
            || Application.platform == RuntimePlatform.OSXPlayer
            || Application.platform == RuntimePlatform.OSXEditor)
        {
            if (m_url_prefix != string.Empty)
                return;

            string path = Application.dataPath;

            while (!Utility.ContainsFolder(path, "Project"))
            {
                path = Path.GetDirectoryName(path);
            }

            path += "/Assets/";

            m_url_prefix = path;
        }
#endif
    }

    private string GetPlatformPrefix()
    {
        string spref = string.Empty;
#if UNITY_STANDALONE_WIN
        spref = "windows/";
#endif
#if UNITY_ANDROID
        spref = "android/";
#endif
#if UNITY_IPHONE
        spref = "iPhone/";
#endif
#if UNITY_WP8
        spref = "wp/";
#endif
        return spref;
    }

    public string GetFileUrl(string name, string folder, string ext, bool checkPlatform, bool streamAsset)
    {
        CheckPrefixUrl();

        name = name.ToLower();


#if UNITY_EDITOR
        /// LY edit begin ///
        string url = m_url_prefix;
        if (string.IsNullOrEmpty(folder) == false)
        {
            url = Path.Combine(m_url_prefix, folder) + "/";
        }
        /// LY edit end ///
        if (Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.WindowsEditor
            || Application.platform == RuntimePlatform.OSXPlayer
            || Application.platform == RuntimePlatform.OSXEditor)
        {
            if (checkPlatform)
                return "file://" + url + GetPlatformPrefix() + name + ext;
            else
            {
                if (!Directory.Exists(url)) url = Path.GetFullPath("../Table/client/tbl/");
                return "file://" + url + name + ext;
            }
        }
        else if (Application.platform == RuntimePlatform.Android)
#else
        if (Application.platform == RuntimePlatform.Android)
#endif
        {
            if (streamAsset)
            {
                //string path = Application.persistentDataPath + '/' + name + ext;
                //if (File.Exists(path))
                //{
                //    return "file://" + path;
                //}
                //else
                //{
                //    return "jar:file://" + Application.dataPath + "!/assets/" + name + ext;
                //}

                ////                return "jar:file://" + Application.dataPath + "!/assets/" + name + ext;




                string fileLastPath = string.Format("table/{0}", name + ext);
                string path = Path.Combine(Application.streamingAssetsPath, fileLastPath);
                //return path;
                //return "file://" + path;

                if (File.Exists(path))
                {
                    return path;
                }
                else
                {
                    return "jar:file://" + Application.dataPath + "!/assets/table/" + name + ext;
                }
            }
            else
                return Path.GetFileNameWithoutExtension(name);
        }
        else if (Application.platform == RuntimePlatform.WindowsPlayer)
        {
            string strPath = "file://" + Path.GetFullPath("data/windows/" + name + ext);
            strPath = strPath.Replace("\\", "/");

            return strPath;
        }
        else if (Application.platform == RuntimePlatform.IPhonePlayer)
        {
            //if (streamAsset)
            //{
            //    string path = Application.persistentDataPath + '/' + name + ext;
            //    if (File.Exists(path))
            //    {
            //        return "file://" + path;
            //    }
            //    else
            //    {
            //        return "file://" + Application.dataPath + "/Raw/" + name + ext;
            //    }
            //}
            //else
            //    return Path.GetFileNameWithoutExtension(name);

            if (streamAsset)
            {
                /*string path = Application.streamingAssetsPath + "/table/" + name + ext;

                iTrace.Log("LY", string.Format("表格路径1:{0}", path));

                if (File.Exists(path))
                {
                    iTrace.Log("LY", string.Format("表格路径2:{0}", path));
                    return path;
                }
                else*/
                {
                    string path = "file://" + Application.dataPath + "/Raw/table/" + name + ext;
                    iTrace.Log("LY", string.Format("表格路径3:{0}", path));
                    return path;
                }
            }
            else
                return Path.GetFileNameWithoutExtension(name);
        }
        else
        {
            if (streamAsset)
                return "file://" + m_url_prefix + name + ext;
            else
                return Path.GetFileNameWithoutExtension(name);
        }
    }

    public FileStream OpenFile(string fileUrl)
    {
#if UNITY_EDITOR
        if (Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.WindowsEditor
            || Application.platform == RuntimePlatform.OSXPlayer
            || Application.platform == RuntimePlatform.OSXEditor)
        {
            string url = fileUrl.Replace("file://", "");

            if (File.Exists(url))
            {
                FileStream fs = File.OpenRead(url);
                return fs;
            }
            else
            {
                iTrace.Log("LY", "File Not Exist : " + url);
                return null;
            }
        }
        else
#endif
        {
            string url;
            if (Application.platform == RuntimePlatform.Android)
            {
                url = fileUrl.Replace("jar:", "");
                url = url.Replace("file://", "");
            }
            else
                url = fileUrl.Replace("file://", "");

            FileStream fs = File.OpenRead(url);
            return fs;
        }

    }

    public byte[] LoadFile(string name, string folder)
    {
        if (cacheTableData.ContainsKey(name))
        {
            return cacheTableData[name];
        }

        byte[] data = null;

        if (AssetPath.ExistInPersistent)
        {
            string url = AssetPath.Persistent + "/" + folder + "/" + name;
            FileStream fs = File.OpenRead(url);
            data = new byte[fs.Length];
            fs.Read(data, 0, (int)fs.Length);
            fs.Close();
            fs.Dispose();

            return data;
        }

#if UNITY_EDITOR
        if (Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.WindowsEditor
            || Application.platform == RuntimePlatform.OSXPlayer
            || Application.platform == RuntimePlatform.OSXEditor)
        {
            string filename = GetFileUrl(name, folder, string.Empty, false, false);
            string url = filename.Replace("file://", "");

            if (File.Exists(url))
            {
                FileStream fs = File.OpenRead(url);
                data = new byte[fs.Length];
                fs.Read(data, 0, (int)fs.Length);
                fs.Close();
                fs.Dispose();
            }
            else
            {
                iTrace.Log("LY", "File Not Exist : " + url);
            }
        }
        else
#endif
        {
            string ext = Path.GetExtension(name);
            string file = Path.GetFileNameWithoutExtension(name);
            string url = GetFileUrl(file, "", ext, true, true);
            //Utility.PrintLog(string.Format("open file:{0}", url));

            if (Application.platform == RuntimePlatform.Android)
            {
                url = url.Replace("jar:", "");
                url = url.Replace("file://", "");
            }
            else
                url = url.Replace("file://", "");

            FileStream fs = File.OpenRead(url);
            data = new byte[fs.Length];
            fs.Read(data, 0, (int)fs.Length);
            fs.Close();
            fs.Dispose();
        }

        return data;
    }

    private string GetFileFullname(string name, string folder)
    {
        string filename = "";
#if UNITY_EDITOR
        if (Application.platform == RuntimePlatform.WindowsPlayer
            || Application.platform == RuntimePlatform.WindowsEditor
            || Application.platform == RuntimePlatform.OSXPlayer
            || Application.platform == RuntimePlatform.OSXEditor)
        {
            filename = GetFileUrl(name, folder, string.Empty, false, false);
        }
        else
#endif
        {
            string ext = Path.GetExtension(name);
            string file = Path.GetFileNameWithoutExtension(name);
            filename = GetFileUrl(file, "", ext, true, true);
        }
        return filename;
    }


    public void LoadTableFile(List<string> nameList, string folder, bool bCache, Action cb)
    {
        //iTrace.Log("Loong", "开始加载表格配置");
        float tFileNum = nameList.Count;
        int tCount = 0;
        for (int a = 0; a < tFileNum; a++)
        {
            string filename = nameList[a];
            string fullname = "";
            if (AssetPath.ExistInPersistent)
            {
                fullname = AssetPath.WwwPersistent + "/" + folder + "/" + filename;
            }
            else
            {
                fullname = GetFileFullname(filename, folder);
            }

            Global.Main.StartCoroutine(WWWLoadFile(fullname, (byte[] arr) =>
            {
                if (bCache && !cacheTableData.ContainsKey(filename))
                {
                    cacheTableData.Add(filename, arr);
                }

                tCount++;
                float pro = tCount / tFileNum;
                //iTrace.eLog("Loong", string.Format("加载第{0}个配置:{1},进度:{2}", tCount, filename, pro));
                if (Ipro != null) Ipro.SetProgress(pro);
                if (tCount >= tFileNum)
                {
                    if (cb != null) cb();
                }
            }));
        }
    }

    //public void LoadFile(string name, string folder, bool bCache, Action cb)
    //{
    //    string fullname = GetFileFullname(name, folder);

    //    Global.mainMono.StartCoroutine(WWWLoadFile(fullname, (byte[] arr) =>
    //    {
    //        if (bCache && !cacheTableData.ContainsKey(name))
    //        {
    //            cacheTableData.Add(name, arr);
    //        }
    //        if (cb != null)
    //            cb();
    //    }));
    //}

    public IEnumerator AsynLoadFile(string name, string folder, bool bCache, Action cb)
    {
        string fullname = GetFileFullname(name, folder);
        yield return Global.Main.StartCoroutine(WWWLoadFile(fullname, (byte[] arr) =>
        {
            if (bCache && !cacheTableData.ContainsKey(name))
            {
                cacheTableData.Add(name, arr);
            }
            if (cb != null)
                cb();
        }));
        yield break;
    }

    public void ClearCacheFile()
    {
        cacheTableData.Clear();
    }

    public IEnumerator WWWLoadFile(string fullname, Action<byte[]> cb)
    {
        using (UnityWebRequest request = UnityWebRequest.Get(fullname))
        {
            yield return request.SendWebRequest();
            //iTrace.LogWarning("LY", "表格路径X:" + fullname);
            if (!string.IsNullOrEmpty(request.error))
            {
                string path = fullname.Substring(7);
                FileStream file = File.OpenRead(path);
                if (file != null)
                {
                    byte[] data = new byte[file.Length];
                    file.Read(data, 0, (int)file.Length);
                    cb(data);
                }

                iTrace.Log("LY", "www error:" + request.error);
                yield break;
            }

            cb(request.downloadHandler.data);

        }
        yield break;
    }
}

