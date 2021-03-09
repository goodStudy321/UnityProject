using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
[CustomEditor(typeof(UIFlyScale), true)]
public class UIFlyScaleInspector : UIFlyInspector
{
    void Awake()
    {
        CustomAwake();
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        GUI.changed = false;
        UIFlyScale fly = mfly as UIFlyScale;
        bool isScale = fly.isScale;
        float scaleIn = fly.scaleIn;
        float scaleOut = fly.scaleOut;
        isScale = EditorGUILayout.Toggle("Is Scale", fly.isScale);
        if (isScale)
        {
            scaleIn = EditorGUILayout.FloatField("Scale In", fly.scaleIn);
            scaleOut = EditorGUILayout.FloatField("Scale Out", fly.scaleOut);
        }
        if (GUI.changed)
        {
            NGUIEditorTools.RegisterUndo("Fly Change", mfly);
            fly.isScale = isScale;
            fly.scaleIn = scaleIn;
            fly.scaleOut = scaleOut;
        }
        bool isDestroy = mfly.isDestroy;
        if (NGUIEditorTools.DrawHeader("Finish"))
        {
            NGUIEditorTools.BeginContents();
            isDestroy = EditorGUILayout.Toggle("Is Destroy", mfly.isDestroy);
            NGUIEditorTools.EndContents();
        }
        if (GUI.changed)
        {
            NGUIEditorTools.RegisterUndo("Fly Change", mfly);
            mfly.isDestroy = isDestroy;
        }
    }

    protected override void CustomAwake()
    {
        mfly = target as UIFlyScale;
    }
}
