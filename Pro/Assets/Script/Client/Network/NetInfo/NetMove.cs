using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;
using PathTool;

public class NetMove
{
    #region Client --> Server
    /// <summary>
    /// �����ƶ���Ŀ���
    /// </summary>
    public static void RequestMoveTo(long point)
    {
        m_move_point_tos moveInfo = ObjPool.Instance.Get<m_move_point_tos>();
        moveInfo.point = point;
        NetworkClient.Send<m_move_point_tos>(moveInfo);
    }

    /// <summary>
    /// ���߷����������ƶ�·����
    /// </summary>
    /// <param name="point"></param>
    public static void RequestWalkTo(long point)
    {
        m_move_role_walk_tos walkInfo = ObjPool.Instance.Get<m_move_role_walk_tos>();
        walkInfo.pos = point;
        NetworkClient.Send<m_move_role_walk_tos>(walkInfo);
    }

    /// <summary>
    /// ����ҡ���ƶ�
    /// </summary>
    /// <param name="point"></param>
    public static void RequestStickMove(long point)
    {
        m_stick_move_tos moveInfo = ObjPool.Instance.Get<m_stick_move_tos>();
        moveInfo.pos = point;
        NetworkClient.Send<m_stick_move_tos>(moveInfo);
    }

    /// <summary>
    /// ���͵�λ�ƶ�
    /// </summary>
    /// <param name="unit"></param>
    public static void SendMove(Unit unit, Vector3 desPos, SendMoveType smType)
    {
        if (Global.Mode == PlayMode.Local)
            return;
        if (unit == null)
            return;
        long ownerUID = User.instance.MapData.UID;
        if (unit.UnitUID != ownerUID)
        {
            if (unit.ParentUnit == null)
                return;
            if (unit.ParentUnit.UnitUID != ownerUID)
                return;
        }
        if (!MSFrameCount.instance.CanSendPoint(smType))
            return;
        long point = GetPointInfo(desPos, unit.UnitTrans.localEulerAngles.y);
        if (smType == SendMoveType.SendMoveRoleWalk)
            RequestWalkTo(point);
        else if (smType == SendMoveType.SendMovePoint)
            RequestMoveTo(point);
        else if (smType == SendMoveType.SendStickMove)
            RequestStickMove(point);
    }

    /// <summary>
    /// ����ֱ�Ӹı�λ��
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="desPos">Ŀ���</param>
    /// <param name="mapId">��ͼId��0--������ͼ</param>
    /// <param name="jumpId">��תID��Ϊ0ʱ����ת����ת</param>
    /// <param name="desJumpId">��תID��Ϊ0ʱ����ת����ת</param>
    public static void RequestChangePosDir(Unit unit, Vector3 desPos, int mapId = 0, int jumpId = 0, int desJumpId = 0)
    {
        if (Global.Mode == PlayMode.Local)
            return;
        if (unit == null)
            return;
        m_map_change_pos_tos changePos = ObjPool.Instance.Get<m_map_change_pos_tos>();
        long point = GetPointInfo(desPos, unit.UnitTrans.localEulerAngles.y);
        changePos.dest_pos = point;
        changePos.map_id = mapId;
        changePos.jump_id = jumpId;
        changePos.dest_jump_id = desJumpId;
        NetworkClient.Send<m_map_change_pos_tos>(changePos);
    }

    /// <summary>
    /// �����ƶ����
    /// </summary>
    /// <param name="unit"></param>
    /// /// <param name="desPos"></param>
    /// <param name="foward"></param>
    public static void RequestMoveRush(Unit unit, Vector3 desPos, Vector3 forward)
    {
        if (Global.Mode == PlayMode.Local)
            return;
        if (unit == null)
            return;
        m_move_rush_tos moveRush = ObjPool.Instance.Get<m_move_rush_tos>();
        Quaternion quaternion = Quaternion.LookRotation(forward);
        float eulerAngleY = quaternion.eulerAngles.y;
        long point = GetPointInfo(desPos, eulerAngleY);
        moveRush.pos = point;
        NetworkClient.Send<m_move_rush_tos>(moveRush);
    }

    /// <summary>
    /// ����ֹͣ�ƶ�
    /// </summary>
    public static void RequestStopMove(long point)
    {
        if (Global.Mode == PlayMode.Local)
            return;
        m_move_stop_tos moveStopInfo = ObjPool.Instance.Get<m_move_stop_tos>();
        moveStopInfo.pos = point;
        NetworkClient.Send<m_move_stop_tos>(moveStopInfo);
    }

    /// <summary>
    /// ��ȡ��λλ�÷�����Ϣ
    /// </summary>
    /// <param name="pos"></param>
    /// <param name="eulerAngleY"></param>
    /// <returns></returns>
    public static long GetPointInfo(Vector3 pos, float eulerAngleY, bool pendant = false, uint sceneId = 0)
    {
        long dir = (long)(eulerAngleY > 0 ? eulerAngleY : 360 + eulerAngleY);
        Vector2 position = Vector2.zero;
        if (!pendant)
        {
            if(sceneId > 0)
            {
                position = MapPathMgr.instance.PosClientToServer(sceneId, pos);
            }
            else
            {
                position = MapPathMgr.instance.PosClientToServer(pos);
            }
        }
        else
            position = MapPathMgr.instance.VPosClientToServer(pos);
        long z = (long)position.y;
        long x = (long)position.x;
        long point = (dir << 40) + (z << 20) + x;
        return point;
    }
    
    #endregion

    #region Server --> Client
    /// <summary>
    /// �����ƶ�
    /// </summary>
    public static void ResponeMove(object obj)
    {
        m_move_point_toc moveInfo = obj as m_move_point_toc;
        if (moveInfo.actor_id == User.instance.MapData.UID)
            return;
        SetMoveInfo(moveInfo.actor_id, moveInfo.point);
    }

    /// <summary>
    /// ҡ��
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeStkMove(object obj)
    {
        m_stick_move_toc moveInfo = obj as m_stick_move_toc;
        if (moveInfo.actor_id == User.instance.MapData.UID)
            return;
        SetMoveInfo(moveInfo.actor_id, moveInfo.pos);
    }

    /// <summary>
    /// �����ƶ���Ϣ
    /// </summary>
    /// <param name="unitId"></param>
    /// <param name="pos"></param>
    public static void SetMoveInfo(long unitId,long pos)
    {
        Unit unit = UnitMgr.instance.FindUnitByUid(unitId);
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        if (unit.Mount != null)
        {
            unit = unit.Mount;
            if (!UnitHelper.instance.CanUseUnit(unit))
                return;
        }
        unit.mNetUnitMove.IsNormalMoveStop = false;
        SetPositionFoward(unit, pos, true);
        SetMoveSpeed(unit, MoveType.Normal);
        if (unit.ActionStatus == null)
            return;
        unit.ActionStatus.FTtarget = null;
        unit.ActionStatus.ChangeMoveAction();
    }

    /// <summary>
    /// �����ƶ�����
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeMoveRush(object obj)
    {
        m_map_change_pos_toc changePos = obj as m_map_change_pos_toc;
        Unit unit = UnitMgr.instance.FindUnitByUid(changePos.actor_id);
        if (unit == null)
            return;
        if (changePos.type == (int)MoveType.Rush)
        {
            if (changePos.actor_id == User.instance.MapData.UID)
                return;
            if (unit.Mount != null)
                unit = unit.Mount;
            if (!UnitHelper.instance.CanUseUnit(unit))
                return;
            DirectSetUnitPosAndRotate(unit, changePos.src_pos);
            SetPositionFoward(unit, changePos.dest_pos, true);
            SetMoveSpeed(unit, MoveType.Rush);
            if (unit.ActionStatus == null)
                return;
            unit.ActionStatus.FTtarget = null;
            unit.ActionStatus.ChangeMoveAction();
            unit.mNetUnitMove.SetRotateSpeed(unit);
        }
        else if(changePos.type == (int)MoveType.BePull)
        {
            if (unit.Mount != null)
                unit = unit.Mount;
            if (!UnitHelper.instance.CanUseUnit(unit))
                return;
            SetPositionFoward(unit, changePos.dest_pos, false);
            SetMoveSpeed(unit, MoveType.BePull);
        }
        else if(changePos.type == (int)MoveType.None)
        {
            Unit role = unit;
            if (unit.Mount != null)
                unit = unit.Mount;
            if (unit == null)
                return;
            if (unit.UnitTrans == null)
                return;
            DirectSetUnitPosAndRotate(unit, changePos.dest_pos);
            PendantMgr.instance.SetLocalPendantsShowState(role, true, OpStateType.MoveToPoint);
        }
        else if(changePos.type == (int)MoveType.Jump)
        {
            if (!UnitHelper.instance.CanUseUnit(unit))
                return;

            if (unit == InputMgr.instance.mOwner)
                return;

            int jump_id = changePos.jump_id;
            unit.mNetUnitMove.ServerCallJumpPath(unit, (uint)jump_id);
        }
    }

    /// <summary>
    /// ����ֹͣ�ƶ�
    /// </summary>
    public static void ResponeStopMove(object obj)
    {
        m_move_stop_toc moveStopInfo = obj as m_move_stop_toc;
        if (moveStopInfo.actor_id == User.instance.MapData.UID)
            return;
        Unit unit = UnitMgr.instance.FindUnitByUid(moveStopInfo.actor_id);
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        if (unit.Mount != null)
        {
            unit = unit.Mount;
            if (!UnitHelper.instance.CanUseUnit(unit))
                return;
        }
        unit.mNetUnitMove.IsNormalMoveStop = true;
        SetPositionFoward(unit, moveStopInfo.pos, false);
        SetMoveSpeed(unit, MoveType.Normal);
        if (unit.ActionStatus == null)
            return;
        unit.ActionStatus.FTtarget = null;
        unit.ActionStatus.ChangeMoveAction();
    }

    /// <summary>
    /// ���õ�λλ�÷���
    /// </summary>
    public static void SetPositionFoward(Unit unit, long point, bool isWalk, bool pendant = false)
    {
        Vector3 pos = GetPositon(point, pendant);
        Vector3 foward = unit.UnitTrans.forward;
        if (isWalk)
        {
            Vector3 dir = GetForward(unit.Position, pos);
            if (dir != Vector3.zero)
                foward = dir;
            else
                return;
        }
        else
        {
            foward = GetForward(point);
        }
        unit.mNetUnitMove.SetMoveFoward(foward);
        unit.mNetUnitMove.SetMoveDesPos(pos);
    }

    /// <summary>
    /// �����ƶ��ٶ�
    /// </summary>
    /// <param name="unit"></param>
    /// <param name=""></param>
    public static void SetMoveSpeed(Unit unit, MoveType moveType)
    {
        unit.mNetUnitMove.SetMoveSpeed(unit, moveType);
    }

    /// <summary>
    /// ֱ��������λ��ĳ��λ��
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponePosition(object obj)
    {
        m_move_sync_toc rolePosition = obj as m_move_sync_toc;
        Unit unit = UnitMgr.instance.FindUnitByUid(rolePosition.actor_id);
        if (unit.Mount != null)
            unit = unit.Mount;
        if (!UnitHelper.instance.CanUseUnit(unit))
            return;
        DirectSetUnitPosAndRotate(unit, rolePosition.pos);
    }

    /// <summary>
    /// ֱ�����õ�λλ���Լ�����
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="point"></param>
    public static void DirectSetUnitPosAndRotate(Unit unit, long point)
    {
        unit.mNetUnitMove.Clear();
        float eulerAngelY = GetOrientation(point);
        unit.SetOrientation(eulerAngelY);
        Vector3 pos = GetPositon(point);
        unit.Position = pos;
    }

    /// <summary>
    /// ��ȡ����
    /// </summary>
    /// <param name="point"></param>
    /// <returns></returns>
    public static float GetOrientation(long point)
    {
        float eulerAngelY = Getdir(point);
        eulerAngelY *= Mathf.Deg2Rad;
        return eulerAngelY;
    }

    /// <summary>
    /// ��ȡ����
    /// </summary>
    /// <param name="point"></param>
    /// <returns></returns>
    public static Vector3 GetForward(long point)
    {
        float eulerA = Getdir(point);
        Vector3 eulerAngle = new Vector3(0, eulerA, 0);
        Quaternion quaternion = Quaternion.Euler(eulerAngle);
        Vector3 forward = quaternion * Vector3.forward;
        return forward;
    }

    /// <summary>
    /// ��ȡ����
    /// </summary>
    /// <param name="srcPos"></param>
    /// <param name="desPos"></param>
    /// <returns></returns>
    public static Vector3 GetForward(Vector3 srcPos, Vector3 desPos)
    {
        srcPos.y = desPos.y = 0;
        Vector3 forward = desPos - srcPos;
        return forward;
    }

    /// <summary>
    /// ��ȡ����
    /// </summary>
    /// <param name="point">�������������Ĳ���</param>
    /// <returns></returns>
    public static float Getdir(long point)
    {
        long dir = point >> 40;
        return (float)dir;
    }

    /// <summary>
    /// ��ȡλ��
    /// </summary>
    /// <param name="point">�������������Ĳ���</param>
    /// <returns></returns>
    public static Vector3 GetPositon(long point, bool pendant = false)
    {
        Vector3 pos = Vector3.zero;
        long dir = point >> 40;
        dir = dir << 40;
        long posZ = (point - dir) >> 20;
        pos.z = posZ;
        posZ = posZ << 20;
        long posX = point - dir - posZ;
        pos.x = posX;
        if (!pendant)
            pos = MapPathMgr.instance.PosServerToClient((int)pos.x, (int)pos.z);
        else
            pos = MapPathMgr.instance.VPosServerToClient((int)pos.x, (int)pos.z);
        RaycastHit hitTerrain;
        Vector3 position = new Vector3(pos.x, 100 + pos.y, pos.z);
        Ray ray = new Ray(position, Vector3.down);
        if (Physics.Raycast(ray, out hitTerrain, 300, 1 << LayerMask.NameToLayer("Ground")))
            pos.y = hitTerrain.point.y;
        return pos;
    }

    #endregion
}
