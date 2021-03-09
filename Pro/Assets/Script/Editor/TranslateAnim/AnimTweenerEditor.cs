using UnityEngine;
using UnityEditor;

#if UNITY_EDITOR
[CustomEditor(typeof(AnimTweener), true)]
public class AnimTweenerEditor : Editor
{
	public override void OnInspectorGUI ()
	{
		GUILayout.Space(6f);
        ATEditorUtility.SetLabelWidth(110f);
		base.OnInspectorGUI();
		DrawCommonProperties();
	}

	protected void DrawCommonProperties ()
	{
        AnimTweener tw = target as AnimTweener;

		if (ATEditorUtility.DrawHeader("Tweener"))
		{
            ATEditorUtility.BeginContents();
            ATEditorUtility.SetLabelWidth(110f);

			GUI.changed = false;

            AnimTweener.AnimType style = (AnimTweener.AnimType)EditorGUILayout.EnumPopup("Play Style", tw.style);
			AnimationCurve curve = EditorGUILayout.CurveField("Animation Curve", tw.animationCurve, GUILayout.Width(170f), GUILayout.Height(62f));
			//UITweener.Method method = (UITweener.Method)EditorGUILayout.EnumPopup("Play Method", tw.method);

			GUILayout.BeginHorizontal();
			float dur = EditorGUILayout.FloatField("Duration", tw.duration, GUILayout.Width(170f));
			GUILayout.Label("seconds");
			GUILayout.EndHorizontal();

			if (GUI.changed)
			{
                ATEditorUtility.RegisterUndo("Tween Change", tw);
				tw.animationCurve = curve;
				//tw.method = method;
				tw.style = style;
				tw.duration = dur;
                EditorUtility.SetDirty(tw);
			}
            ATEditorUtility.EndContents();
		}

        ATEditorUtility.SetLabelWidth(80f);
	}
}
#endif