using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraOperationInfo
{
    public float H;
    public float R;
    public float VA;
    public float HA;
    public float Fov;

    private float TargetH;
    private float TargetR;
    private float TargetVA;
    private float TargetHA;
    private float TargetFov;

    private float SpeedH;
    private float SpeedR;
    private float SpeedVA;
    private float SpeedHA;
    private float SpeedFov;

    private float TimeH;
    private float TimeR;
    private float TimeVA;
    private float TimeHA;
    private float TimeFov;

    private float OffsetH;
    private float OffsetR;
    private float OffsetVA;
    private float OffsetHA;
    private float OffsetFov;

    public float value = 100.0f;

    public CameraOperationInfo()
    {

    }

    public void UpdateBase(float h, float r, float va, float ha, float fov)
    {
        H = h;
        R = r;
        VA = va;
        HA = ha;
        Fov = fov;
        /// 移动前摄像机位置 ///
        OffsetH = H;
        OffsetR = R;
        OffsetVA = VA;
        OffsetHA = HA;
        OffsetFov = Fov;
    }

    public void UpdateTarget(float h, float r, float va, float ha, float fov)
    {
        TargetH = h;
        TargetR = r;
        TargetVA = va;
        TargetHA = ha;
        TargetFov = fov;
        /// 移动前摄像机位置 ///
        OffsetH = H;
        OffsetR = R;
        OffsetVA = VA;
        OffsetHA = HA;
        OffsetFov = Fov;
    }

    #region 更新数据
    public void UpdateH(float tar, float time)
    {
        TargetH = tar;
        if (time == 0) return;
        time = time * value;
        TimeH = time;
        SpeedH = (TargetH - H) / TimeH;
    }

    public void UpdateR(float tar, float time)
    {
        TargetR = tar;
        if (time == 0) return;
        time = time * value;
        TimeR = time;
        SpeedR = (TargetR - R) / TimeR;
    }

    public void UpdateVA(float tar, float time)
    {
        TargetVA = tar;
        if (time == 0) return;
        time = time * value;
        TimeVA = time;
        SpeedVA = (TargetVA - VA) / TimeVA;
    }

    public void UpdateHA(float tar, float time)
    {
        tar %= 360;
        if (tar < 0) tar += 360;
        TargetHA = tar;

        HA %= 360;
        if (HA < 0)
        {
            HA += 360;
        }
        else
        {
            int o = (int)(TargetHA - HA);
            if (o / 180 >= 1)
            {
                HA += 360;
            }
        }
        OffsetHA = HA;


        if (time == 0) return;
        time = time * value;
        TimeHA = time;

        /***
        int r = Mathf.FloorToInt(Mathf.Abs(dv) / 180);
        int sign = r < 1 ? 1 : -1;
        if (sign != 0) TargetHA += 360 * sign;
        **/
        SpeedHA = (TargetHA - HA) / TimeHA;
    }

    public void UpdateFOV(float tar, float time)
    {
        TargetFov = tar;
        if (time == 0) return;
        TimeFov = time * value;
        SpeedFov = (TargetFov - Fov) / TimeFov;
    }
    #endregion

    public void Restore(float timeH = 0.0f, float timeR = 0.0f, float timeVA = 0.0f, float timeHA = 0.0f, float timeFov = 0.0f)
    {
        TargetH = OffsetH;
        TargetR = OffsetR;
        TargetVA = OffsetVA;
        TargetHA = OffsetHA;
        TargetFov = OffsetFov;

        if (timeH != 0) SpeedH = (TargetH - H) / (timeH * value);
        if (timeR != 0) SpeedR = (TargetR - R) / (timeR * value);
        if (timeVA != 0) SpeedVA = (TargetVA - VA) / (timeVA * value);
        if (timeHA != 0) SpeedHA = (TargetHA - HA) / (timeHA * value);
        if (timeFov != 0) SpeedFov = (TargetFov - Fov) / (timeFov * value);
    }

    public bool Change()
    {
        bool h = Change(ref H, TargetH, SpeedH);
        bool r = Change(ref R, TargetR, SpeedR);
        bool va = Change(ref VA, TargetVA, SpeedVA);
        bool ha = Change(ref HA, TargetHA, SpeedHA);
        bool fov = Change(ref Fov, TargetFov, SpeedFov);
        if (!h && !r && !va && !ha && !fov)
        {
            Clear();
            return false;
        }
        return true;
    }

    public bool Change(ref float cur, float tar, float speed)
    {
        //if(cur != tar && tar != 0)
        if (Mathf.Abs(cur - tar) > 0.001 && tar != 0)
        {
            if (speed != 0)
            {
                cur += speed;
                if (speed < 0 && cur <= tar || speed > 0 && cur >= tar)
                {
                    cur = tar;
                    return false;
                }
                return true;
            }
            else
            {
                cur = tar;
                return false;
            }
        }
        return false;
    }

    private void Clear()
    {

        TargetH = 0.0f;
        TargetR = 0.0f;
        TargetVA = 0.0f;
        TargetHA = 0.0f;
        TargetFov = 0.0f;

        SpeedH = 0.0f;
        SpeedR = 0.0f;
        SpeedVA = 0.0f;
        SpeedHA = 0.0f;
        SpeedFov = 0.0f;

        TimeH = 0.0f;
        TimeR = 0.0f;
        TimeVA = 0.0f;
        TimeHA = 0.0f;
        TimeFov = 0.0f;
    }
}
