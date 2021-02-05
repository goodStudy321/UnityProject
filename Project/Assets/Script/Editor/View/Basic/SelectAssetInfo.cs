using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    [Serializable]
    public class SelectAssetInfo : SelectInfo
    {
        [SerializeField]
        private Object asset = null;

        public Object Asset
        {
            get { return asset; }
            set { asset = value; }
        }

        public SelectAssetInfo()
        {

        }

        public override void OnGUI(Object obj)
        {
            EditorGUILayout.LabelField(asset.name);
        }
    }
}

