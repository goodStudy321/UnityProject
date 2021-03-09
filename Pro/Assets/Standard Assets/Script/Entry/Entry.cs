//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 17:06:01
//=============================================================================

#if UNITY_ANDROID

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Serialization;
using UnityEngine.Networking;

namespace Loong.Game
{
    /// <summary>
    /// Entry
    /// </summary>
    public class Entry : MonoBehaviour
    {
        #region 字段
        private int lblSize = 0;
        private string msg = "";
        private string streamPath = null;
        private string persistPath = null;
        private string codeName = "png.bytes";
        private string persistCodePath = null;
        #endregion

        #region 属性
        [XmlAttribute()]
        public string Msg
        {
            get { return msg; }
            set { msg = value; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法q
        private void Awake()
        {
            SetPath();
            Setting();
            LoadFromFile();
        }

        /// <summary>
        /// 设置路径
        /// </summary>
        private void SetPath()
        {
            streamPath = Application.streamingAssetsPath + "/";
            persistPath = Application.persistentDataPath + "/";
            persistCodePath = persistPath + codeName;

        }

        /// <summary>
        /// 工程设置
        /// </summary>
        private void Setting()
        {
            Screen.fullScreen = true;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
            QualitySettings.vSyncCount = 0;
            Application.targetFrameRate = 30;
            Application.runInBackground = true;
        }

        /*/// <summary>
        /// 加载
        /// </summary>
        private void LoadFromAB()
        {
            bool isPersist = NeedFromPersisit();
            if (isPersist)
            {
                var ab = AssetBundle.LoadFromFile(persistCodePath);
                StartUp(ab);
            }
            else
            {
                StartCoroutine(YieldLoad());
            }

        }*/

        private void LoadFromFile()
        {
            bool isPersist = NeedFromPersisit();
            if (isPersist)
            {
                if (File.Exists(persistCodePath))
                {
                    try
                    {
                        using (var stream = new FileStream(persistCodePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                        {
                            int length = (int)stream.Length;
                            var bytes = new byte[length];
                            stream.Read(bytes, 0, length);
                            StartUp(bytes);
                            Debug.Log("Loong, load fromfile suc");
                        }
                    }
                    catch (Exception e)
                    {
                        Debug.LogWarningFormat("Loong, entry err:{0}", e.Message);
                        StartCoroutine(YieldLoad(false));
                    }
                }
                else
                {
                    Debug.LogWarningFormat("Loong, entry {0} not exist!", persistCodePath);
                    StartCoroutine(YieldLoad(false));
                }
            }
            else
            {
                StartCoroutine(YieldLoad(false));
            }
        }

        private IEnumerator YieldLoad(bool isAB = true)
        {
            var path = GetStreamingWWWPath() + codeName;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                DownloadHandlerAssetBundle handler = new DownloadHandlerAssetBundle(request.url, uint.MaxValue);
                request.downloadHandler = handler;
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    Save(persistCodePath, request.downloadHandler.data);
                    if (isAB)
                    {
                        var ab = handler.assetBundle;
                        StartUp(ab);
                    }
                    else
                    {
                        StartUp(handler.data);
                    }
                    Debug.Log("Loong, yieldload suc");
                }
                else
                {
                    msg = string.Format("Loong, load:{0}, err:{1}", path, err);
                    Debug.LogError(msg);
                }
            }
        }

        private void StartUp(AssetBundle ab)
        {
            var names = ab.GetAllAssetNames();
            var ta = ab.LoadAsset<TextAsset>(names[0]);
            var bytes = ta.bytes;
            StartUp(bytes);
        }

        private void StartUp(byte[] bytes)
        {
            var asm = Assembly.Load(bytes);
            var typeName = "MainEntry";
            var funcName = "Start";
            StartUp(asm, typeName, funcName);
        }

        private void Save(string path, byte[] bytes)
        {
            FileStream fs = null;
            bool suc = true;
            try
            {
                fs = new FileStream(path, FileMode.Create);
                fs.Write(bytes, 0, bytes.Length);
                Debug.LogWarningFormat("Loong,entry save:{0}", path);
            }
            catch (Exception e)
            {
                suc = false;
                Debug.LogWarningFormat("Loong entry save:{0} err:{1}", path, e.Message);
            }
            if (fs != null)
            {
                fs.Dispose();
            }
            if (suc) return;
            System.Threading.Thread.Sleep(20);
            Save(path, bytes);
        }

        private void StartUp(Assembly asm, string typeName, string funcName)
        {
            var type = asm.GetType(typeName);
            if (type == null)
            {
                msg = string.Format("{0} not type {1}", asm.FullName, typeName);
            }
            else
            {
                var obj = Activator.CreateInstance(type);
                var method = type.GetMethod(funcName);
                method.Invoke(obj, null);
            }
        }

        private void OnGUI()
        {
            lblSize = GUI.skin.label.fontSize;
            GUI.skin.label.fontSize = 30;
            GUILayout.Label(msg, GUILayout.MinHeight(40));
            GUI.skin.label.fontSize = lblSize;
        }
        #endregion

        #region 私有方法
        /// <summary>
        /// true:需要从沙盒读取
        /// </summary>
        /// <returns></returns>
        private bool NeedFromPersisit()
        {
            var fileName = "AppVer.txt";
            var outVerPath = persistPath + fileName;
            if (!File.Exists(outVerPath)) return false;
            var inVerPath = GetStreamingWWWPath() + fileName;
            int inVer = 0, outVer = 0;
            using (UnityWebRequest request = UnityWebRequest.Get(inVerPath))
            {
                var UWRAsynOp = request.SendWebRequest();
                while (!UWRAsynOp.isDone) continue;
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    var text = request.downloadHandler.text.Trim();
                    if (!int.TryParse(text, out inVer))
                    {
                        Debug.LogErrorFormat("Loong,can not parse inVer text:{0}", text);
                    }
                }
                else
                {
                    Debug.LogErrorFormat("Loong,get ver from:{0} ,err:{1}", inVerPath, err);
                }
            }
            using (var read = new StreamReader(outVerPath, Encoding.UTF8))
            {
                var text = read.ReadToEnd().Trim();
                if (!int.TryParse(text, out outVer))
                {
                    Debug.LogErrorFormat("Loong,can not parse outVer text:{0}", text);
                }
            }
            return (outVer >= inVer);

        }

        /// <summary>
        /// 获取流路径
        /// </summary>
        /// <returns></returns>
        private string GetStreamingWWWPath()
        {
#if UNITY_EDITOR
            return "file:///" + streamPath;
#elif UNITY_ANDROID
            return "jar:file://" + Application.dataPath + "!/assets/";
#elif UNITY_IOS
            return "file://" + Application.dataPath + "/Raw/";
#else
        	return "file:///" + streamPath;		
#endif
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}

#endif