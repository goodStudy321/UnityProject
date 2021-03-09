using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[ExecuteInEditMode]
[CustomEditor(typeof(UIFlyAlpha), true)]
public class UIFlyAlphaInspector : UIFlyInspector
{
    void Awake()
    {
        CustomAwake();
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        GUI.changed = false;
        UIFlyAlpha fly = mfly as UIFlyAlpha;
        bool isfade = fly.isFade;
        float fadein = fly.fadeIn;
        float fadeout = fly.fadeOut;
        isfade = EditorGUILayout.Toggle("Is Fade", fly.isFade);
        if (isfade)
        {
            fadein = EditorGUILayout.FloatField("Fade In", fly.fadeIn);
            fadeout = EditorGUILayout.FloatField("Fade Out", fly.fadeOut);
        }
        if (GUI.changed)
        {
            NGUIEditorTools.RegisterUndo("Fly Change", mfly);
            fly.isFade = isfade;
            fly.fadeIn = fadein;
            fly.fadeOut = fadeout;
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
        mfly = target as UIFlyAlpha;
    }
}
