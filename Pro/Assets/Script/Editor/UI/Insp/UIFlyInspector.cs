using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
[CustomEditor(typeof(UIFly), true)]
public class UIFlyInspector : UIWidgetContainerEditor
{
    protected UIFly mfly;
    //protected GameObject tt;
    private void Awake()
    {
        CustomAwake();
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        //tt = (GameObject)EditorGUILayout.ObjectField("Target", mfly.target, typeof(GameObject), true);
        //if (GUI.changed) mfly.target = tt;
        NGUIEditorTools.SetLabelWidth(80f);
        mfly.anchors1 = EditorGUILayout.Vector3Field("Anchors Pos 1", mfly.anchors1);
        mfly.anchors2 = EditorGUILayout.Vector3Field("Anchors Pos 2", mfly.anchors2);
        //if(tt == null)
            mfly.targetPos = EditorGUILayout.Vector3Field("Target Pos", mfly.targetPos);
        EditorGUILayout.Space();
        GUILayout.BeginHorizontal();
        mfly.time = EditorGUILayout.FloatField("Duration", mfly.time, GUILayout.Width(170f));
        GUILayout.Label("seconds");
        GUILayout.EndHorizontal();
        mfly.endDelay = EditorGUILayout.FloatField("Delay", mfly.endDelay, GUILayout.Width(170f));

        bool isDestroy = EditorGUILayout.Toggle("Is Destroy", mfly.isDestroy);
        if (isDestroy != mfly.isDestroy) mfly.isDestroy = isDestroy;
        EditorGUILayout.Space();
    }

    protected virtual void CustomAwake()
    {
        mfly = target as UIFly;
    }
}
