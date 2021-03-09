using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using System;


public enum PickType
{
    ShowPick=1, //能看见并且能拾取的
    ShowNoPick=2, //能看见但是不能拾取的
    NoShow=3, //不能看见（当然也不能拾取的）
}

public class DropData
{
    /// <summary>
    /// 掉落物初始位置
    /// </summary>
    public Vector3 startDropPos = Vector3.zero;

    /// <summary>
    /// 拾取的对象id
    /// </summary>
    public UInt64 dropId = 0;

    /// <summary>
    /// 掉落物品type_id 一般为道具ID
    /// </summary>
    public UInt32 type_id = 0;

    /// <summary>
    /// 掉落物数量
    /// </summary>
    public int num = 0;

    /// <summary>
    /// 绑定类型
    /// </summary>
    public bool isBind = false;

    /// <summary>
    /// 怪物位置
    /// </summary>
    public Vector3 monster_pos = Vector3.zero;

    /// <summary>
    /// 怪物类型id
    /// </summary>
    public UInt32 monster_type_id = 0;

    /// <summary>
    /// 掉落物状态
    /// </summary>
    public PickType pickType = PickType.NoShow;

}

namespace Loong.Game
{
    public static class DropMgr
    {
        #region
        private static List<DropData> dataList = new List<DropData>();
        private static Dictionary<UInt64, DropInfo> dropDic = new Dictionary<UInt64, DropInfo>();
        private static List<UInt64> dropKeys = new List<ulong>();
        private static List<UInt64> pickList = new List<UInt64>();//能拾取
        private static Dictionary<UInt64, DropInfo> delDic = new Dictionary<ulong, DropInfo>(); //拾取完成飞向玩家然后移除
        private static List<UInt64> delKeys = new List<ulong>();
        private static Transform mRoot = null;
        private static Dictionary<int, bool> quaDic=new Dictionary<int, bool>(); //拾取的颜色

        public static bool isFull = false;
        public static bool stopPick = false; //停止拾取（背包已满并且没有可跳过背包满的道具)
        public static List<int> ignoreUFXDic = new List<int>();
        public static UInt32 spriteId = 0;
        /// <summary>
        /// 拾取完所有可拾取掉落回调
        /// </summary>
        public static Action PAllDropAct = null;
        /// <summary>
        /// 没有拾取的后端通知移除的
        /// </summary>
        public static Action<UInt64> removeAct = null;
        #endregion
        public static Transform MRoot
        {
            get
            {
                return mRoot;
            }
        }


        /// <summary>
        /// 拾取成功事件
        /// </summary>
        public static event Action<DropInfo> pickSuc = null;
        public static event Action<ulong> pickScs = null;

        public static void Initialize()
        {
            mRoot = TransTool.CreateRoot(typeof(DropMgr).Name);

            EventMgr.Add("m_pickUp", ResqPickDrop);
            EventMgr.Add("m_hasSprite", OnHasSprite);
            EventMgr.Add("UpBag", OnUpBag);
            EventMgr.Add(EventKey.PickEquip, OnSelectQua);

            for(int i=0;i<=4;i++)
            {
                quaDic[i] = false;
            }
        }

        public static void ResqPickDrop(params object[] args)
        {
            //1.-----------------------------个人掉落
            //2.-----------------------------组队掉落
            //3.-----------------------------帮派掉落

            UInt64 dropId = Convert.ToUInt64(args[1]);
            if (pickScs != null) pickScs(dropId);
            if (!dropDic.ContainsKey(dropId))
            {
                //Debug.LogError("没有掉落物信息: " + dropId);
                return;
            }

            DropInfo info = dropDic[dropId];
            int error = Convert.ToInt32(args[0]);
            if (error == 0) //拾取成功
            {
                //飞向玩家身上
                delKeys.Add(dropId);
                delDic.Add(dropId, info);
                RemoveDrop(dropId);
            }
            else  //不能拾取
            {
                //Debug.LogError("不能拾取的掉落： " + dropId);
                info.CleanData();
            }
        }

        /// <summary>
        /// 移除掉落物
        /// </summary>
        /// <param name="dropId"></param>
        public static bool DisposeDrop(ulong dropId)
        {
            if (pickScs != null) pickScs(dropId);
            if (delDic.ContainsKey(dropId)) return true;
            else
            {
                if (removeAct != null) removeAct(dropId); 
                return RemoveDrop(dropId, true);
            }
        }

        /// <summary>
        /// 从列表移除
        /// </summary>
        /// <param name="dropId"></param>
        /// <returns></returns>
        public static bool RemoveDrop(ulong dropId, bool isDelete = false)
        {
            if (!dropDic.ContainsKey(dropId))
            {
                if (dataList.Count > 0)
                {
                    for (int i = 0; i < dataList.Count; i++)
                    {
                        if (dataList[i].dropId == dropId)
                        {
                            dataList.RemoveAt(i);
                            return true;
                        }
                    }
                }
                return false;
            }
            else
            {
                DropInfo info = dropDic[dropId];
                if (info == null || info.data == null) return false;
                if (info.CanQuickPick())
                {
                    DropEffect eff = ObjPool.Instance.Get<DropEffect>();
                    eff.Init(info.Position);
                }
                if (info.data.pickType == PickType.ShowPick)
                {
                    pickList.Remove(dropId);
                    if (pickSuc != null) pickSuc(info);
                    EventMgr.Trigger(EventKey.PickDrop, dropId, info.item.id, info.Position);
                    if (pickList.Count == 0)
                    {
                        if (PAllDropAct != null) PAllDropAct();
                    }
                }
                dropKeys.Remove(dropId);
                dropDic.Remove(dropId);
                if (isDelete == true)
                    info.Dispose();
                SetHasDrop();
                return true;
            }
        }

        public static void OnHasSprite(params object[] args)
        {
            spriteId = Convert.ToUInt32(args[0]);
        }

        public static void OnUpBag(params object [] args)
        {
            isFull = (bool)args[0];
        }

        public static void OnSelectQua(params object[] args)
        {          
            int qua = Convert.ToUInt16(args[0]);
            bool canPick = Convert.ToBoolean(args[1]);

            
            quaDic[qua] = canPick;


            for(int i=0;i<pickList.Count;i++)
            {
                if (pickScs != null) pickScs(pickList[i]);
            }
            pickList.Clear();
            for(int i=0;i<dropKeys.Count;i++)
            {
                UInt64 id = dropKeys[i];
                DropInfo info = dropDic[id];
                int quality = info.item.quality;
                if (quality > 4) quality = 4;
                bool pick = quaDic[quality];
                if((pick==true || ignoreUFXDic.Contains(info.item.useEffect1))&& info.data.pickType==PickType.ShowPick)
                {
                    pickList.Add(id);
                }              
            }
        }

        private static float countTime = 0.02f;
        private static float tipTime = 3f;
        public static void Update()
        {
            for (int i = delKeys.Count - 1; i >= 0; i--)
            {
                UInt64 key = delKeys[i];
                DropInfo info = delDic[key];
                info.Update();
                if (info.isEnd == true)
                {
                    info.Dispose();
                    delKeys.Remove(key);
                    delDic.Remove(key);
                }
            }

            int count = pickList.Count;
            if (count > 0)
            {
                if (isFull == true)
                {
                    if (tipTime > 0)
                        tipTime -= Time.deltaTime;
                    else
                    {
                        UITip.LocalLog(690016);
                        tipTime = 3f;
                    }
                }
                else
                {
                    tipTime = 3f;
                }
                stopPick = true;
                for (int i = pickList.Count - 1; i >= 0; i--) //能拾取列表
                {
                    UInt64 key = pickList[i];
                    if (dropDic.ContainsKey(key))
                    {
                        DropInfo drop = dropDic[key];
                        drop.UpdateBar();
                        uint id = drop.data.type_id;
                        ItemData data = drop.item;
                        int uFx = data.useEffect1;
                        int qua = data.quality;
                        bool canPick = false;
                        if(uFx==1)
                        {
                            if (qua > 4) qua = 4;
                            canPick = quaDic[qua];
                        }
                        else
                        {
                            canPick = quaDic[0];
                        }
                        //忽视背包已满和品质限制
                        if(((ignoreUFXDic.Contains(drop.item.useEffect1) || id <= 101)|| isFull == false) && canPick==true )
                        {
                            stopPick = false;
                            if (drop.isLock == true || drop.isBegan == false) continue;
                            drop.UpdateDistance();  //检测是否可拾取范围
                        }
                    }
                }
            }
          

            if (dataList.Count > 0)
            {
                countTime -= Time.deltaTime;
                if (countTime < 0f)
                {
                    Create(dataList[0]);
                    countTime = 0.02f;
                }
            }
        }

        /// <summary>
        /// 检测是否还有掉落物
        /// </summary>
        public static void SetHasDrop()
        {
            if (pickList.Count == 0) User.instance.MapData.HasDrop = false;
            else User.instance.MapData.HasDrop = true;
        }

        /// <summary>
        /// 服务器返回创建
        /// </summary>
        /// <param name="actor"></param>
        public static void Create(p_map_actor actor)
        {
            if (actor.drop_extra == null)
            {
                iTrace.Error("xiaoyu", string.Format("UID为:{0}的掉落物配置(drop_extra)数据为空", actor.actor_id));
                return;
            }
            else
            {
                Vector3 pos = NetMove.GetPositon(actor.pos);
                DropData data = ObjPool.Instance.Get<DropData>();
                data.startDropPos = pos;
                data.dropId = (UInt64)actor.actor_id;
                data.type_id = (UInt32)actor.drop_extra.type_id;
                data.num = actor.drop_extra.num;
                data.isBind = actor.drop_extra.bind;
                data.monster_pos = NetMove.GetPositon(actor.drop_extra.monster_pos);
                data.monster_type_id = (UInt32)actor.drop_extra.monster_type_id;
                bool show = Show(actor.drop_extra.broadcast_roles);
                bool pick = PickUp(actor.drop_extra.owner_roles);
                if (show == true && pick == true)
                {
                    StopNav();
                    data.pickType = PickType.ShowPick;
                }
                else if (show == true && pick == false)
                    data.pickType = PickType.ShowNoPick;
                else
                    data.pickType = PickType.NoShow;
                dataList.Add(data);
            }
        }


        public static void Create(DropData data)
        {
            UInt64 id = data.type_id;
            ItemData item = null;
            if (id > 70000 && id < 90000)
            {
                ItemCreate create = ItemCreateManager.instance.Find(id);
                if (create != null)
                {
                    int cate = User.instance.MapData.Category;
                    if (cate == 1)
                        id = create.w1;
                    else
                        id = create.w2;
                }
            }
            item = ItemDataManager.instance.Find((UInt32)id);
            if (item == null)
            {
                iTrace.eLog("xiaoyu", string.Format("道具为空，表id为{0}", data.type_id));
                return;
            }
            if (data.pickType == PickType.NoShow) return;
            if (string.IsNullOrEmpty(item.model))
            {
                iTrace.Error("xiaoyu", string.Format("ID为:{0}的掉落物没有配置模型", data.type_id));
                return;
            }
            else
            {
                if (String.IsNullOrEmpty(item.model))
                {
                    iTrace.Log("xiaoyu", string.Format("没有发现该道具的模型，id为", data.type_id));
                    return;
                }

                AssetMgr.LoadPrefab(item.model, CallBack);
            }
        }

        private static void CallBack(GameObject go)
        {
            if (dataList == null || dataList.Count == 0) return;
            DropData data = dataList[0];
            UInt64 dropId = data.dropId;
            if (dropDic.ContainsKey(dropId))
            {      

                DropInfo info = dropDic[dropId];
                info.Dispose();
                dropDic.Remove(dropId);
                if (dropKeys.Contains(dropId)) dropKeys.Remove(dropId);
            }
            DropInfo drop = ObjPool.Instance.Get<DropInfo>();
            drop.InitData(go, data);

            //掉落物曲线
            BezierCurveScript bezier = go.GetComponent<BezierCurveScript>();
            if (bezier == null)
            {
                go.AddComponent<BezierCurveScript>();
                bezier = go.GetComponent<BezierCurveScript>();
            }
            float x = data.monster_pos.x;
            float y = data.monster_pos.y + 5;
            float z = data.monster_pos.z;
            bezier.SetBezier(data.monster_pos, data.startDropPos, new Vector3(x,y,z),0.3f, DropMgr.DropDone, drop);

            dropKeys.Add(dropId);
            dropDic.Add(dropId, drop);
            int qua = drop.item.quality;
            if (qua > 4) qua = 4;
            if (data.pickType == PickType.ShowPick &&(quaDic[qua] ==true || ignoreUFXDic.Contains(drop.item.useEffect1)))
                pickList.Add(dropId);          
            dataList.Remove(data);

            SetHasDrop();
        }

        private static Vector3 curPos = Vector3.zero;
        public static void CreateHitEff()
        {
            if (GameSceneManager.instance.CurCopyType != CopyType.Glod)
                return;
            if (dataList.Count == 0)
                return;
            curPos = dataList[0].monster_pos;
            AssetMgr.LoadPrefab("FX_M_BossLongGui_hit", LoadBossHit);
        }
        private static void LoadBossHit(GameObject go)
        {
            go.transform.localPosition = curPos;

        }
         private static void DropDone(object obj)
        {
            if(obj==null)
            {
                Debug.LogError("DropDone ==null");
                return;
            }
            DropInfo drop = obj as DropInfo;
            drop.isBegan = true;
            drop.DropEff();
        }

        /// <summary>
        /// 当前玩家是否可见
        /// </summary>
        /// <param name="info"></param>
        /// <returns></returns>
        public static bool Show(List<Int64> broadcast_roles)
        {
            if (broadcast_roles.Count == 0) return true;
            else
            {
                if (broadcast_roles.Contains(User.instance.MapData.UID)) return true;
                else return false;
            }
        }

        /// <summary>
        /// 当前玩家是否可拾取
        /// </summary>
        /// <param name="info"></param>
        /// <returns></returns>
        public static bool PickUp(List<Int64> owner_roles)
        {
            if (owner_roles.Count == 0) return true;
            else
            {
                if (owner_roles.Contains(User.instance.MapData.UID)) return true;
                else return false;
            }         
        }

        /// <summary>
        /// 切换场景单元清除数据
        /// </summary>
        public static void CleanDropList()
        {
            //Debug.Log("beg clean drop data");
            tipTime = 3f;
            while (dataList.Count > 0)
            {
                DropData data = dataList[dataList.Count - 1];
                if (data != null)
                {
                    ObjPool.Instance.Add(data);
                }
                dataList.Remove(data);
            }

            while(dropKeys != null && dropKeys.Count>0)
            {
                UInt64 key = dropKeys[dropKeys.Count - 1];
                dropKeys.Remove(key);

                if (dropDic.ContainsKey(key))
                {
                    DropInfo info = dropDic[key];
                    info.Dispose();
                    dropDic.Remove(key);
                }
            }
            dropDic.Clear();
            pickList.Clear();

            if (PAllDropAct != null) PAllDropAct();

            while (delKeys != null && delKeys.Count>0)
            {
                UInt64 key = delKeys[delKeys.Count - 1];
                delKeys.Remove(key);

                if(delDic.ContainsKey(key))
                {
                    DropInfo info = delDic[key];
                    info.Dispose();
                    delDic.Remove(key);
                }
            }
            delDic.Clear();

            HangupMgr.instance.ResetDrop();
            SetHasDrop();
            //Debug.Log("end clean drop data");
        }

        /// <summary>
        /// 停止寻路
        /// </summary>
        public static void StopNav()
        {
            if (stopPick == true) return;
            if (!HangupMgr.instance.IsAutoHangup)
                return;
            Unit unit = InputVectorMove.instance.MoveUnit;
            if (unit == null)
                return;
            if (!unit.mUnitMove.InPathFinding)
                return;
            unit.mUnitMove.StopNav();
        }

        /// <summary>
        /// 获取可拾取掉落物
        /// </summary>
        /// <returns></returns>
        public static DropInfo GetCanPickupDrop()
        {
            if (stopPick)
                return null;
            DropInfo drop = null;
            if (pickList.Count == 0)
                return null;
            float minDisSqr = 400;
            Vector3 unitPos = InputVectorMove.instance.MoveUnit.Position;
            for(int i = 0; i < pickList.Count; i++)
            {
                ulong pickupId = pickList[i];
                if (dropDic.ContainsKey(pickupId) == false) return null;
                DropInfo curDrop = dropDic[pickupId];
                if (curDrop.isLock)
                    continue;
                if (!curDrop.isBegan)
                    continue;
                if (curDrop.IsInPickDis())
                    continue;
                float disSqr = Vector3.SqrMagnitude(unitPos - curDrop.Position);
                if (disSqr > minDisSqr)
                    continue;
                minDisSqr = disSqr;
                drop = curDrop;
            }
            return drop;

           
        }

        public static void Clear()
        {
            Debug.Log("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
            ignoreUFXDic.Clear();
        }
    }
}
