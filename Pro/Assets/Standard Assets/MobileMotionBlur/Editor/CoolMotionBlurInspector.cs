using UnityEditor;
using UnityEngine;
//using System.Collections;


[CustomEditor(typeof(CoolMotionBlur))]
public class CoolMotionBlurInspector : Editor
{
    private CoolMotionBlur mTarget;

    void OnEnable()
    {
        mTarget = target as CoolMotionBlur;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (mTarget == null)
        {
            return;
        }

        mTarget.BlurCenter = EditorGUILayout.Vector2Field("模糊中心（0.0-1.0）", mTarget.BlurCenter);
        mTarget.BlurStrength = EditorGUILayout.FloatField("模糊程度", mTarget.BlurStrength);
    }
}
