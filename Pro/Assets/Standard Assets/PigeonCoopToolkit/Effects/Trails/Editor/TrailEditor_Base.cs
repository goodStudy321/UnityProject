using System.Collections.Generic;
using UnityEditor;
using UnityEngine;


namespace PigeonCoopToolkit.Effects.Trails.Editor
{
    
    public class TrailEditor_Base : UnityEditor.Editor
    {
        public static TrailPreviewUtillity win;

        public override void OnInspectorGUI()
        {

            TrailRenderer_Base t = (TrailRenderer_Base)serializedObject.targetObject;
            if (t == null)
                return;

            DrawDefaultInspector();
            GUILayout.Space(10);
            if(GUILayout.Button("Open preview"))
            {
                // Get existing open window or if none, make a new one:
                win = (TrailPreviewUtillity)EditorWindow.GetWindow(typeof(TrailPreviewUtillity), true, "Normalized Trail Preview");
                win.minSize = new Vector2(900, 140);
                win.maxSize = new Vector2(900, 140);
                win.Trail = t;
            }
            
        }
    }
}
