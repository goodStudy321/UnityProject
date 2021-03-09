using UnityEngine;
using System.Collections;

public class ExeScript 
{
    public static readonly ExeScript instance = new ExeScript();

    private ExeScript()
    {

    }
    public void ExeScriptCmd(string scriptCmd, Unit mParentUnit)
    {
        if (string.IsNullOrEmpty(scriptCmd))
            return;
        string[] strs = scriptCmd.Split('(');
        int len = strs.Length;
        if (len != 2)
            return;
        string scriptname = strs[0];
        string parameter = strs[1];
        string mParam = parameter.Remove(parameter.Length - 1);
        switch (scriptname)
        {
            case "CameraShake":
                {
                    if (!UnitHelper.instance.IsOwner(mParentUnit))
                        return;
                    string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
                    if (args.Length != 3)
                        return;
                    CameraShake(float.Parse(args[0]), float.Parse(args[1]), float.Parse(args[2]));
                    break;
                }
            case "CameraPull":
                {
                    if (!UnitHelper.instance.IsOwner(mParentUnit))
                        return;
                    string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
                    if (args.Length != 2)
                        return;
                    CameraPull(float.Parse(args[0]), float.Parse(args[1]));
                    break;
                }
            case "SetOutlineSkin":
                {
                    string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
                    if (args.Length != 5)
                        return;
                    SetOutlineSkin(mParentUnit, int.Parse(args[0]), int.Parse(args[1]), int.Parse(args[2]), float.Parse(args[3]), float.Parse(args[4]));
                    break;
                }
            case "ResetNormalSkin":
                {
                    ResetNormalSkin(mParentUnit);
                    break;
                }
            case "JumpDone":
                {
                    mParentUnit.mNetUnitMove.LandAnimFinish();
                    break;
                }
            case "Dissolve":
                {
                    mParentUnit.mUnitDissolve.init(mParentUnit);
                    float dslTime;
                    if (!float.TryParse(mParam, out dslTime))
                        return;
                    ExeDissolve(mParentUnit,dslTime);
                    break;
                }
            case "CameraBlur":
                {
                    if (Global.Mode == PlayMode.Network)
                        return;
                    if (!UnitHelper.instance.IsOwner(mParentUnit))
                        return;
                    string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
                    if (args.Length != 4)
                        return;
                    ExeCameraBlur(float.Parse(args[0]), float.Parse(args[1]),float.Parse(args[2]),float.Parse(args[3]));
                    break;
                }
            //case "OutLineSkin":
            //    {
            //        string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
            //        if (args.Length != 2)
            //            return;
            //        BegOutLine(mParentUnit, float.Parse(args[0]), float.Parse(args[1]));
            //        break;
            //    }
        }
    }

    /// <summary>
    /// �������
    /// </summary>
    /// <param name="time">��ʱ��</param>
    /// <param name="frequence">Ƶ��</param>
    /// <param name="amplitude">���</param>
    public void CameraShake(float time = 0.5f, float frequence = 90, float amplitude = 30)
    {
        Loong.Game.CameraMgr.CameraShake.AddCameraShakeEffectData(time, frequence, amplitude);
    }

    /// <summary>
    /// ���������
    /// </summary>
    /// <param name="distance"></param>
    /// <param name="time"></param>
    public void CameraPull(float distance, float time)
    {
        Loong.Game.CameraMgr.CameraPull.SetCameraPull(distance,time);
    }

    /// <summary>
    /// �����ⷢ��Ƥ��
    /// </summary>
    /// <param name="mOwner"></param>
    /// <param name="r"></param>
    /// <param name="g"></param>
    /// <param name="b"></param>
    /// <param name="outlineWidth"></param>
    /// <param name="emission"></param>
    public void SetOutlineSkin(Unit mOwner, int r, int g, int b, float outlineWidth, float emission)
    {
    }

    /// <summary>
    /// ��������Ƥ��
    /// </summary>
    /// <param name="mOwner"></param>
    public void ResetNormalSkin(Unit mOwner)
    {
    }
    
    /// <summary>
    /// ִ���ܽ�
    /// </summary>
    /// <param name="mOwner"></param>
    public void ExeDissolve(Unit mOwner, float dissolveTime)
    {
        if (mOwner == null)
            return;
        ActionStatus actStatus = mOwner.ActionStatus;
        if (actStatus == null)
            return;
        int startParam = 0;
        if (actStatus.ActionState == ActionStatus.EActionStatus.EAS_Born)
            startParam = 1;
        mOwner.mUnitDissolve.SetDissolve(dissolveTime, startParam);
    }

    /// <summary>
    /// ��ʼ�ܽ�
    /// </summary>
    /// <param name="mOwner"></param>
    /// <param name="outlineVal"></param>
    /// <param name="outlineTime"></param>
    public void BegOutLine(Unit mOwner, float outlineVal, float outlineTime)
    {
        if (mOwner == null)
            return;
        mOwner.mUnitOutline.SetOutLine(outlineVal, outlineTime);
    }

    /// <summary>
    /// ִ�������ģ��
    /// </summary>
    /// <param name="blurCenX">ģ������X��</param>
    /// <param name="blurCenY">ģ������Y��</param>
    /// <param name="strengh">ģ��ǿ��</param>
    /// <param name="lastTime">����ʱ��</param>
    public void ExeCameraBlur(float blurCenX, float blurCenY, float strengh, float lastTime)
    {
        if (blurCenX < 0)
            blurCenX = 0;
        if (blurCenX > 1)
            blurCenX = 1;
        if (blurCenY < 0)
            blurCenY = 0;
        if (blurCenY > 1)
            blurCenY = 1;
        if (strengh < 0)
            strengh = 0;
        Vector2 blurCen = new Vector2(blurCenX, blurCenY);
        CameraEffMgr.instance.StartEffBlur(lastTime, blurCen, strengh);
    }
}
