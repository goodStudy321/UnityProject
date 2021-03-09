using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimationTest : MonoBehaviour
{
    //方向键
    public AnimationClip A;
    public AnimationClip S;
    public AnimationClip D;
    public AnimationClip W;

    //待机状态
    public AnimationClip Idle;
    //技能键
    public AnimationClip J;
    public AnimationClip K;
    public AnimationClip L;
    public AnimationClip U;
    public AnimationClip I;

    private Animation Animation;
    private bool mPlayingSkill = false;

    /// <summary>
    /// 摄像机
    /// </summary>
    public Vector3 CamOff;
    public Transform Camera;

    // Use this for initialization
    void Start()
    {
        Camera = GameObject.Find("Main Camera").transform;
        CamOff = new Vector3(0, 5, -5);
        Camera.position = transform.TransformPoint(CamOff);
        Camera.LookAt(transform);
        Animation = GetComponentInChildren<Animation>();
    }

    /// <summary>
    /// 处理技能键
    /// </summary>
    private void ProcessSkillKey()
    {
        if (Input.GetKey(KeyCode.J))
        {
            if (J == null) return;
            mPlayingSkill = true;
            Animation.Play(J.name);
            Debug.Log("skill");
        }
        else if (Input.GetKey(KeyCode.K))
        {
            if (K == null) return;
            mPlayingSkill = true;
            Animation.Play(K.name);
        }
        else if (Input.GetKey(KeyCode.L))
        {
            if (L == null) return;
            mPlayingSkill = true;
            Animation.Play(L.name);
        }
        else if (Input.GetKey(KeyCode.U))
        {
            if (U == null) return;
            mPlayingSkill = true;
            Animation.Play(U.name);
        }
        else if (Input.GetKey(KeyCode.I))
        {
            if (I == null) return;
            mPlayingSkill = true;
            Animation.Play(I.name);
        }
    }

    /// <summary>
    /// 处理移动键
    /// </summary>
    private void ProcessMoveKey()
    {
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
        {
            string animationName = GetMoveName(A);
            if (mPlayingSkill) return;
            if (Animation.IsPlaying(animationName)) return;
            Animation.CrossFade(animationName, 0.1f);
        }
        else if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
        {
            string animationName = GetMoveName(S);
            if (mPlayingSkill) return;
            if (Animation.IsPlaying(animationName)) return;
            Animation.CrossFade(animationName, 0.1f);
        }
        else if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
        {
            string animationName = GetMoveName(D);
            if (mPlayingSkill) return;
            if (Animation.IsPlaying(animationName)) return;
            Animation.CrossFade(animationName, 0.1f);
        }
        else if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
        {
            string animationName = GetMoveName(W);
            if (mPlayingSkill) return;
            if (Animation.IsPlaying(animationName)) return;
            Animation.CrossFade(animationName, 0.1f);
        }
        else
        {
            string idleName = "idle";
            if (Idle != null)
                idleName = Idle.name;
            if (mPlayingSkill) return;
            if (Animation.IsPlaying(idleName)) return;
            Animation.CrossFade(idleName, 0.1f);
        }
    }

    /// <summary>
    /// 获取移动动作名
    /// </summary>
    /// <param name="animationClip"></param>
    /// <returns></returns>
    private string GetMoveName(AnimationClip animationClip)
    {
        if (animationClip != null)
            return animationClip.name;
        if (A != null)
            return A.name;
        if (S != null)
            return S.name;
        if (D != null)
            return D.name;
        if (W != null)
            return W.name;
        return null;
    }

    /// <summary>
    /// 更新移动和方向
    /// </summary>
    private void UpdateMoveAndRotation()
    {
        if (mPlayingSkill) return;
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");
        if (horizontal == 0 && vertical == 0)
            return;
        if (mPlayingSkill) return;
        Vector2 delta = new Vector2(horizontal, vertical);

        Vector3 playerDir = Vector3.zero;
        Vector3 deltaPos = Vector3.zero;
        Vector3 movedirx = transform.position - Camera.position;

        movedirx = movedirx.normalized;
        movedirx.y = 0;
        Vector3 movedirz = Vector3.Cross(Vector3.up, movedirx);
        float lengths = 3 * Time.deltaTime;
        Vector3 enddirx = movedirx * delta.y;
        Vector3 enddirz = movedirz * delta.x;
        Vector3 enddir = enddirx + enddirz;
        deltaPos = enddir.normalized * lengths;

        deltaPos.y = 0;
        Vector3 desPos = transform.position + deltaPos;
        playerDir = (desPos - transform.position).normalized;


        RaycastHit hitTerrain;
        Vector3 position = new Vector3(desPos.x, 10 + desPos.y, desPos.z);
        Ray ray = new Ray(position, Vector3.down);
        if (Physics.Raycast(ray, out hitTerrain, 100, 1 << LayerMask.NameToLayer("Ground")))
        {
            position = new Vector3(position.x, hitTerrain.point.y, position.z);
            desPos = position;
        }
        transform.position = desPos;
        transform.forward = playerDir;

        Camera.rotation = Quaternion.Euler(Camera.localEulerAngles.x, Camera.localEulerAngles.y, 0);
        Camera.position = transform.position + Camera.rotation * Vector3.back * 5;
    }

    /// <summary>
    /// 检测技能动画
    /// </summary>
    private void CheckSkillAnimation()
    {
        if (J != null && Animation.IsPlaying(J.name))
        {
            mPlayingSkill = true;
            return;
        }
        if (K != null && Animation.IsPlaying(K.name))
        {
            mPlayingSkill = true;
            return;
        }
        if (L != null && Animation.IsPlaying(L.name))
        {
            mPlayingSkill = true;
            return;
        }
        if (U != null && Animation.IsPlaying(U.name))
        {
            mPlayingSkill = true;
            return;
        }
        if (I != null && Animation.IsPlaying(I.name))
        {
            mPlayingSkill = true;
            return;
        }
        mPlayingSkill = false;
    }

    // Update is called once per frame
    void Update()
    {
        ProcessSkillKey();
        ProcessMoveKey();
        CheckSkillAnimation();
        UpdateMoveAndRotation();
    }
}
