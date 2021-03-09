/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Xml.Serialization;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// Md5信息集
    /// </summary>
    [System.Serializable]
    public class Md5Set
    {
        #region 字段
        [XmlArrayItem(ElementName = "it")]
        [UnityEngine.SerializeField]
        public List<Md5Info> infos;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public Md5Set()
        {

        }
        public Md5Set(List<Md5Info> infos)
        {
            this.infos = infos;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public bool Read(string path)
        {
            if (!File.Exists(path)) return false;
            if (infos == null) infos = new List<Md5Info>();//infos = new List<Md5Info>(16384);
            var fs = new FileStream(path, FileMode.Open, FileAccess.Read);
            var br = new BinaryReader(fs, Encoding.UTF8);
            bool suc = true;
            try
            {
                int len = br.ReadInt32();
                //Debug.LogFormat("Loong,read mf infos.len:{0}", len);
                if (len > 0)
                {
                    for (int i = 0; i < len; i++)
                    {
                        var info = ObjPool.Instance.Get<Md5Info>();
                        info.Read(br);
                        infos.Add(info);
                    }
                }
                else
                {
                    suc = false;
                }
            }
            catch (Exception e)
            {
                suc = false;
                int len = infos.Count;
                for (int i = 0; i < len; i++)
                {
                    ObjPool.Instance.Add(infos[i]);
                }
                infos.Clear();
                Debug.LogFormat("Loong,read mf err:{0}", e.Message);
            }
            finally
            {
                br.Close();
                fs.Dispose();
            }
            return suc;
        }

        public void Save(string path)
        {
            using (var fs = new FileStream(path, FileMode.Create))
            {
                using (var bw = new BinaryWriter(fs, Encoding.UTF8))
                {
                    if (infos == null)
                    {
                        bw.Write(0);
                    }
                    else
                    {
                        int len = infos.Count;
                        bw.Write(len);
                        for (int i = 0; i < len; i++)
                        {
                            var info = infos[i];
                            info.Save(bw);
                        }
                    }
                }
            }
        }
        #endregion
    }
}