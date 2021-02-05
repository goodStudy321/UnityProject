// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: mission_info.prot

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;


public class MissionInfo : Table.Binary, Table.IKey
{
	#region data
	public class data : Table.Binary
	{
		List<Int32> m_list;
		
		public List<Int32> list
		{
			get { return m_list; }
		}
		
		public override int Load(byte[] buffer, int index)
		{
			Table.Loader loader = new Table.Loader(ref buffer, index);
			loader.Load(ref m_list);
			return loader.Size;
		}
	}
	#endregion
	
	#region param
	public class param : Table.Binary
	{
		List<data> m_list;
		
		public List<data> list
		{
			get { return m_list; }
		}
		
		public override int Load(byte[] buffer, int index)
		{
			Table.Loader loader = new Table.Loader(ref buffer, index);
			loader.Load(ref m_list);
			return loader.Size;
		}
	}
	#endregion
	
	#region reward
	public class reward : Table.Binary
	{
		List<data> m_list;
		
		public List<data> list
		{
			get { return m_list; }
		}
		
		public override int Load(byte[] buffer, int index)
		{
			Table.Loader loader = new Table.Loader(ref buffer, index);
			loader.Load(ref m_list);
			return loader.Size;
		}
	}
	#endregion
	
	UInt32       m_id;
	Table.String m_name;
	UInt16       m_chapter;
	Byte         m_type;
	data         m_three_id;
	Byte         m_quality;
	Byte         m_num;
	Byte         m_turn;
	Table.String m_chapter_name;
	Table.String m_chapter_des;
	UInt32       m_first_id;
	UInt32       m_next_id;
	Byte         m_need_lv;
	Byte         m_auto_receive;
	Byte         m_auto_submit;
	Byte         m_show_talk;
	UInt32       m_npc_receive;
	UInt32       m_npc_submit;
	Table.String m_talk_resceive;
	Table.String m_mission_talk;
	Table.String m_talk_submit;
	data         m_auto_point;
	data         m_hide_monster;
	Byte         m_target;
	param        m_target_param;
	Table.String m_custom_text;
	Int32        m_exp_reward;
	reward       m_item_reward;
	Int32        m_quite_scene_id;
	Int32        m_scene_change;
	
	public const UInt32 Version = 2882205836;
	
	public UInt64 Key()
	{
		return m_id;
	}
	
	public UInt32 id
	{
		get { return m_id; }
	}
	
	public string name
	{
		get { return m_name; }
	}
	
	public UInt16 chapter
	{
		get { return m_chapter; }
	}
	
	public Byte type
	{
		get { return m_type; }
	}
	
	public data threeId
	{
		get { return m_three_id; }
	}
	
	public Byte quality
	{
		get { return m_quality; }
	}
	
	public Byte num
	{
		get { return m_num; }
	}
	
	public Byte turn
	{
		get { return m_turn; }
	}
	
	public string chapterName
	{
		get { return m_chapter_name; }
	}
	
	public string chapterDes
	{
		get { return m_chapter_des; }
	}
	
	public UInt32 firstId
	{
		get { return m_first_id; }
	}
	
	public UInt32 nextId
	{
		get { return m_next_id; }
	}
	
	public Byte needLv
	{
		get { return m_need_lv; }
	}
	
	public Byte autoReceive
	{
		get { return m_auto_receive; }
	}
	
	public Byte autoSubmit
	{
		get { return m_auto_submit; }
	}
	
	public Byte showTalk
	{
		get { return m_show_talk; }
	}
	
	public UInt32 npcReceive
	{
		get { return m_npc_receive; }
	}
	
	public UInt32 npcSubmit
	{
		get { return m_npc_submit; }
	}
	
	public string talkResceive
	{
		get { return m_talk_resceive; }
	}
	
	public string missionTalk
	{
		get { return m_mission_talk; }
	}
	
	public string talkSubmit
	{
		get { return m_talk_submit; }
	}
	
	public data autoPoint
	{
		get { return m_auto_point; }
	}
	
	public data hideMonster
	{
		get { return m_hide_monster; }
	}
	
	public Byte target
	{
		get { return m_target; }
	}
	
	public param targetParam
	{
		get { return m_target_param; }
	}
	
	public string customText
	{
		get { return m_custom_text; }
	}
	
	public Int32 expReward
	{
		get { return m_exp_reward; }
	}
	
	public reward itemReward
	{
		get { return m_item_reward; }
	}
	
	public Int32 quiteSceneId
	{
		get { return m_quite_scene_id; }
	}
	
	public Int32 sceneChange
	{
		get { return m_scene_change; }
	}
	
	public override int Load(byte[] buffer, int index)
	{
		Table.Loader loader = new Table.Loader(ref buffer, index);
		loader.Load(ref m_id).Load(ref m_name).Load(ref m_chapter).Load(ref m_type).Load(ref m_three_id).Load(ref m_quality).Load(ref m_num).Load(ref m_turn).Load(ref m_chapter_name).Load(ref m_chapter_des).Load(ref m_first_id).Load(ref m_next_id).Load(ref m_need_lv).Load(ref m_auto_receive).Load(ref m_auto_submit).Load(ref m_show_talk).Load(ref m_npc_receive).Load(ref m_npc_submit).Load(ref m_talk_resceive).Load(ref m_mission_talk).Load(ref m_talk_submit).Load(ref m_auto_point).Load(ref m_hide_monster).Load(ref m_target).Load(ref m_target_param).Load(ref m_custom_text).Load(ref m_exp_reward).Load(ref m_item_reward).Load(ref m_quite_scene_id).Load(ref m_scene_change);
		return loader.Size;
	}
}

// source: R 任务配置.xls, sheet: Sheet1
public sealed class MissionInfoManager : Table.Manager<MissionInfo>
{
	private static readonly MissionInfoManager ms_instance = new MissionInfoManager();
	
	private MissionInfoManager()
	{
	}
	
	public static MissionInfoManager instance
	{
		get { return ms_instance; }
	}
	
	public string source
	{
		get { return "mission_info.tbl"; }
	}
	
	public bool Load(string path)
	{
		Register();
		return Load(path, source, MissionInfo.Version);
	}
	
	public MissionInfo Find(UInt32 key)
	{
		return FindInternal(key);
	}
	
	#region new helper
	public static object NewMissionInfo()
	{
		return new MissionInfo();
	}
	public static object NewMissionInfodata()
	{
		return new MissionInfo.data();
	}
	
	public static object NewMissionInfoparam()
	{
		return new MissionInfo.param();
	}
	
	public static object NewMissionInforeward()
	{
		return new MissionInfo.reward();
	}
	
	private static void Register()
	{
		Table.NewHelper.Clear();
		Table.NewHelper.Register(typeof(MissionInfo), NewMissionInfo);
		Table.NewHelper.Register(typeof(MissionInfo.data), NewMissionInfodata);
		Table.NewHelper.Register(typeof(MissionInfo.param), NewMissionInfoparam);
		Table.NewHelper.Register(typeof(MissionInfo.reward), NewMissionInforeward);
	}
	#endregion
}

