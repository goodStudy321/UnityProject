using System;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    [Serializable]
    public class SelectInfo
    {
        [SerializeField]
        private bool isSelect = false;

        public bool IsSelect
        {
            get { return isSelect; }
            set { isSelect = value; }
        }

        public virtual void OnGUI(Object obj)
        {

        }
    }
}

