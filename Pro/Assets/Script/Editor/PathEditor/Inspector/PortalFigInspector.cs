using UnityEditor;
using UnityEngine;
//using System.Collections;

//[CanEditMultipleObjects]
[CustomEditor(typeof(PortalFig))]
public class PortalFigInspector : Editor
{
    private PortalFig mTarget;

    void OnEnable()
    {
        mTarget = target as PortalFig;
        if(mTarget.mJumpPaths.Count > 0 && mTarget.mUseAnimNames.Count <= 0)
        {
            for(int a = 0; a < mTarget.mJumpPaths.Count; a++)
            {
                mTarget.mUseAnimNames.Add("");
            }
        }
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if(mTarget == null)
        {
            return;
        }

        mTarget.mPortalId = (uint)Mathf.Abs(EditorGUILayout.IntField("传送口Id", (int)mTarget.mPortalId));
        mTarget.mLinkMapId = (uint)Mathf.Abs(EditorGUILayout.IntField("链接地图Id", (int)mTarget.mLinkMapId));
        mTarget.mLinkPortalId = (uint)Mathf.Abs(EditorGUILayout.IntField("链接传送口Id", (int)mTarget.mLinkPortalId));
        mTarget.mReverse = EditorGUILayout.Toggle("是否反向", mTarget.mReverse);
        mTarget.mUnlockCharLv = (uint)Mathf.Abs(EditorGUILayout.IntField("传送口解锁主角等级", (int)mTarget.mUnlockCharLv));
        mTarget.mUnlockMissionId = Mathf.Abs(EditorGUILayout.IntField("传送口解锁任务Id", mTarget.mUnlockMissionId));

        if (GUILayout.Button("添加跳跃路径") == true)
        {
            mTarget.AddOneJumpPath();
        }
        
        DrawCurve();
    }

    protected void DrawCurve()
    {
        for(int a = 0; a < mTarget.mJumpPaths.Count; a++)
        {

            if (ATEditorUtility.DrawHeader("Curve"))
            {
                ATEditorUtility.BeginContents();
                ATEditorUtility.SetLabelWidth(110f);

                GUI.changed = false;

                mTarget.mJumpPaths[a] = (uint)EditorGUILayout.IntField("曲线Id：", (int)mTarget.mJumpPaths[a]);
                mTarget.mJumpTimeList[a] = EditorGUILayout.FloatField("跳跃时间：", mTarget.mJumpTimeList[a]);
                mTarget.mUseAnimNames[a] = EditorGUILayout.TextField("跳跃动画名称", mTarget.mUseAnimNames[a]);
                AnimationCurve curve = EditorGUILayout.CurveField("Animation Curve", 
                    mTarget.mAnimCurves[a], GUILayout.Width(170f), GUILayout.Height(62f));

                if (GUI.changed)
                {
                    ATEditorUtility.RegisterUndo("Tween Change", mTarget);
                    mTarget.mAnimCurves[a] = curve;
                    EditorUtility.SetDirty(mTarget);
                }

                mTarget.mPreWaitTimeList[a] = EditorGUILayout.FloatField("前置等待时间：", mTarget.mPreWaitTimeList[a]);
                mTarget.mPreAnimList[a] = EditorGUILayout.TextField("前置动画名称", mTarget.mPreAnimList[a]);
                mTarget.mPreFxList[a] = EditorGUILayout.TextField("前置特效名称", mTarget.mPreFxList[a]);
                mTarget.mPPHideList[a] = EditorGUILayout.Toggle("前置等待前隐藏角色", mTarget.mPPHideList[a]);
                mTarget.mPAHideList[a] = EditorGUILayout.Toggle("前置等待后隐藏角色", mTarget.mPAHideList[a]);

                GUILayout.Space(30);

                if(a < mTarget.mJumpPaths.Count - 1)
                {
                    mTarget.mAftWaitTimeList[a] = EditorGUILayout.FloatField("后置等待时间：", mTarget.mAftWaitTimeList[a]);
                    mTarget.mAftAnimList[a] = EditorGUILayout.TextField("后置动画名称", mTarget.mAftAnimList[a]);
                }
                mTarget.mAftFxList[a] = EditorGUILayout.TextField("后置特效名称", mTarget.mAftFxList[a]);
                mTarget.mAPHideList[a] = EditorGUILayout.Toggle("后置等待前隐藏角色", mTarget.mAPHideList[a]);
                if (a < mTarget.mJumpPaths.Count - 1)
                {
                    mTarget.mAAHideList[a] = EditorGUILayout.Toggle("后置等待后隐藏角色", mTarget.mAAHideList[a]);
                }

                if (GUILayout.Button("删除曲线") == true)
                {
                    mTarget.RemoveJumpPath(a);
                }

                ATEditorUtility.EndContents();
            }

            ATEditorUtility.SetLabelWidth(80f);
        }

    }
}
