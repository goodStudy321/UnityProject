using UnityEngine;
using Loong.Game;

public class InputVectorMove
{
    public static readonly InputVectorMove instance = new InputVectorMove();

    private InputVectorMove()
    {

    }
    #region 私有变量
    /// <summary>
    /// 移动键是否按下
    /// </summary>
    private bool mMoveKeyDown = false;
    #endregion

    #region 属性
    /// <summary>
    /// 移动单位
    /// </summary>
    public Unit MoveUnit
    {
        get
        {
            Unit owner = InputMgr.instance.mOwner;
            if (owner == null)
                return null;
            if (owner.Mount == null)
                return owner;
            if (owner.Mount.UnitTrans == null)
                return owner;
            return owner.Mount;
        }
    }
    #endregion

    #region 公有方法
    public void Update()
    {
        if (!UnitHelper.instance.CanMove(InputMgr.instance.mOwner))
            return;
        UpdateMoveDistance();
        UpdateMoveAction();
    }

    /// <summary>
    /// 重置移动按键
    /// </summary>
    public void ResetMoveKeyDown(ProtoBuf.ActionData actionData)
    {
        if (!mMoveKeyDown)
            return;
        if (actionData == null)
            return;
        if (actionData.AnimID[0] != 'W'
            && actionData.AnimID != "N9100")
            return;
        mMoveKeyDown = false;
    }
    
    /// <summary>
    /// 清除
    /// </summary>
    public void Clear()
    {
        mMoveKeyDown = false;
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 更新移动动作
    /// </summary>
    private void UpdateMoveAction()
    {
        bool moveKeyDown = (JoyStickCtrl.instance.mInputVector != Vector2.zero);
        if (mMoveKeyDown == moveKeyDown) return;
        Unit owner = MoveUnit;
        if (owner == null) return;
        if (owner.ActionStatus == null) return;
        if (owner.ActionStatus.ActiveAction == null) return;
        if (moveKeyDown)
        {
            bool result = KeyInput.instance.OnKeyDown(KeyInput.instance.KeyStates[(int)EKeyList.KL_Move]);
            if (result || !result && owner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Move)
            {
                MSFrameCount.instance.StartTimer(SendMoveType.SendStickMove);
                if (owner.ActionStatus.FTtarget != null)
                    owner.ActionStatus.FTtarget = null;
                mMoveKeyDown = moveKeyDown;
                ActionHelper.PlayRidingAnim(owner, true);
            }
        }
        else
        {
            MSFrameCount.instance.StopTimer(SendMoveType.SendStickMove);
            if(owner.ActionStatus.ActiveAction.AnimID != "N0020")
            {
                mMoveKeyDown = moveKeyDown;
                ActionHelper.PlayRidingAnim(owner, false);
                return;
            }
            bool result = KeyInput.instance.OnKeyUp(KeyInput.instance.KeyStates[(int)EKeyList.KL_Move]);
            if (!result) return;
            mMoveKeyDown = moveKeyDown;
            ActionHelper.PlayRidingAnim(owner, false);
            long point = NetMove.GetPointInfo(owner.Position, owner.UnitTrans.localEulerAngles.y);
            NetMove.RequestStopMove(point);
        }
    }

    /// <summary>
    /// 更新移动距离
    /// </summary>
    private void UpdateMoveDistance()
    {
        Vector3 inputVector = JoyStickCtrl.instance.mInputVector;
        if (inputVector == Vector3.zero)
            return;
        Unit owner = MoveUnit;
        if (owner == null)
            return;
        Vector3 playerDir = Vector3.zero;
        if (owner.ActionStatus == null)
            return;
        HangupMgr.instance.ClearAutoInfo();
        HgupPoint.instance.Clear();
        /// LY add begin ///
        //EventMgr.Trigger("BreakPowerSaveMode");
        QualityMgr.instance.ResetPSMTimer(null);
        /// LY add end ///
        User.instance.ResetMisTarID();
        SelectRoleMgr.instance.ResetTRUId();
        if (owner.ActionStatus.ActiveAction.MoveSpeed > 0)
        {
            ClearOtherData(owner);
            Vector3 deltaPos = Vector3.zero;
            Vector3 movedirx = owner.Position - Loong.Game.CameraMgr.transform.position;

            movedirx = movedirx.normalized;
            movedirx.y = 0;
            Vector3 movedirz = Vector3.Cross(Vector3.up, movedirx);
            float deltaTime = Time.deltaTime > 0.05f ? 0.05f : Time.deltaTime;
            float lengths = owner.MoveSpeed * deltaTime;
#if UNITY_EDITOR
            if(Global.Mode == PlayMode.Local)
                lengths = owner.ActionStatus.ActiveAction.MoveSpeed * 0.01f * deltaTime;
#endif
            Vector3 enddirx = movedirx * inputVector.y;
            Vector3 enddirz = movedirz * inputVector.x;
            Vector3 enddir = enddirx + enddirz;
            deltaPos = enddir.normalized * lengths;

            deltaPos.y = 0;
            Vector3 desPos = owner.Position + deltaPos;
            playerDir = (desPos - owner.Position).normalized;
            RaycastHit hit;
            Vector3 orgin = owner.Position + new Vector3(0, 0.5f, 0);
            Ray rayObsta = new Ray(orgin, deltaPos);
            lengths += owner.ActionStatus.Bounding.z;
            if (Physics.Raycast(rayObsta, out hit, lengths, (1 << LayerTool.Wall) | (1 << LayerTool.Unit) | (1 << LayerTool.NPC)))
            {
                if(hit.collider.gameObject.layer == LayerTool.Wall || hit.collider.gameObject.tag == TagTool.ObstacleUnit)
                    desPos = owner.Position;
            }

            RaycastHit hitTerrain;
            Vector3 position = new Vector3(desPos.x, 10 + desPos.y, desPos.z);
            Ray ray = new Ray(position, Vector3.down);
            if (Physics.Raycast(ray, out hitTerrain, 100, 1 << LayerMask.NameToLayer("Ground")))
            {
                position = new Vector3(position.x, hitTerrain.point.y, position.z);
                desPos = position;
            }
            owner.Position = desPos;
            NetMove.SendMove(InputMgr.instance.mOwner, desPos, SendMoveType.SendStickMove);
        }
        //如果动画是技能时不能旋转
        if (owner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Attack
            || owner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Skill)
            return;
        if (!owner.ActionStatus.CanRotate)
            return;
        owner.SetOrientation(Mathf.Atan2(playerDir.x, playerDir.z));
    }

    /// <summary>
    /// 清除其他数据
    /// </summary>
    private void ClearOtherData(Unit owner)
    {
        owner.ActionStatus.FTtarget = null;
        UnitAttackCtrl.instance.Clear();
        UnitWildRush.instance.Clear();
        owner.mUnitMove.StopNav(false);
        owner.ActionStatus.ChangeMoveAction();
    }
    #endregion
}
