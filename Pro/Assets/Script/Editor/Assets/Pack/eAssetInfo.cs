using System.IO;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using System;

namespace Hello.Edit
{
    [Serializable]
    public class eAssetInfo : IDraw, IComparable<eAssetInfo>, IComparer<eAssetInfo>
    {
        [SerializeField]
        [HideInInspector]
        private int lv = 0;

        [SerializeField]
        [HideInInspector]
        private int sort = 0;

        [SerializeField]
        [HideInInspector]
        private string _path = "";

        [XmlAttribute]
        public string path
        {
            get { return _path; }
            set { _path = value; }
        }

        [XmlAttribute]
        public int Lv
        {
            get { return lv; }
            set { lv = value; }
        }

        [XmlAttribute]
        public int Sort
        {
            get { return sort; }
            set { sort = value; }
        }

        [XmlIgnore]
        public bool valid = true;

        [XmlIgnore]
        public string validMsg = "";

        private bool CheckSfx(string sfx)
        {
            if (sfx == Suffix.Js) return false;
            if (sfx == Suffix.CS) return false;
            if (sfx == Suffix.Lua) return false;
            if (sfx == Suffix.Meta) return false;
            return true;
        }

        private void SetPathDialog(Object obj)
        {
            var cur = Directory.GetCurrentDirectory();
            cur += "/Assets";
            string temp = EditorUtility.OpenFilePanel("设置资源路径", cur, "*.*");
            if (string.IsNullOrEmpty(temp)) return;
        }


    }

}

