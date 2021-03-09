/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 * 等级越小越优先
 * 排序越小越优先;并且值<0时,为核心模块
 ============================================================================*/
using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Serialization;

namespace Loong.Game
{
    /// <summary>
    /// MD5信息
    /// </summary>
    [System.Serializable]
    public class Md5Info : IComparer<Md5Info>, IComparable<Md5Info>
    {
        #region 字段

        #endregion

        #region 属性
        /// <summary>
        /// 路径
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public string path;
        /// <summary>
        /// 唯一值,可以是MD5/SHA1 etc
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public string MD5;

        /// <summary>
        /// 版本号
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public int Ver;

        /// <summary>
        /// 大小
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public int Sz;

        /// <summary>
        /// 等级
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public ushort Lv;

        /// <summary>
        /// 排序
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public short St;


        /// <summary>
        /// 选项,1:代表已下载
        /// </summary>
        [XmlAttribute]
        [SerializeField]
        public byte Op;

        #endregion

        #region 构造方法
        public Md5Info()
        {

        }
        public Md5Info(string path, string md5)
        {
            this.path = path;
            MD5 = md5;
        }

        public Md5Info(string path, string md5, int ver) : this(path, md5)
        {
            Ver = ver;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Read(BinaryReader br)
        {
            path = br.ReadString();
            MD5 = br.ReadString();
            Ver = br.ReadInt32();
            Sz = br.ReadInt32();
            Lv = br.ReadUInt16();
            St = br.ReadInt16();
            Op = br.ReadByte();
        }

        public void Save(BinaryWriter bw)
        {
            bw.Write(path);
            bw.Write(MD5);
            bw.Write(Ver);
            bw.Write(Sz);
            bw.Write(Lv);
            bw.Write(St);
            bw.Write(Op);
        }

        public void Copy(Md5Info other)
        {
            Op = other.Op;
            Sz = other.Sz;
            Lv = other.Lv;
            MD5 = other.MD5;
            Ver = other.Ver;
            St = other.St;
            path = other.path;
        }

        public int CompareTo(Md5Info rhs)
        {
            if (Lv < rhs.Lv) return -1;
            if (Lv > rhs.Lv) return 1;
            if (St < rhs.St) return -1;
            if (St > rhs.St) return 1;
            if (Ver < rhs.Ver) return 1;
            if (Ver > rhs.Ver) return -1;
            return path.CompareTo(rhs.path);
        }

        public int Compare(Md5Info lhs, Md5Info rhs)
        {
            return lhs.CompareTo(rhs);
        }
        #endregion
    }
}