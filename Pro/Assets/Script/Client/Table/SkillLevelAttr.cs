// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: Skill_Level_Attr.prot

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;


public class SkillLevelAttr : Table.Binary, Table.IKey
{
	#region passive_buff
	public class passive_buff : Table.Binary
	{
		List<UInt32> m_list;
		
		public List<UInt32> list
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
	
	#region direct_buf
	public class direct_buf : Table.Binary
	{
		List<UInt32> m_list;
		
		public List<UInt32> list
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
	
	#region hit_buf
	public class hit_buf : Table.Binary
	{
		List<UInt32> m_list;
		
		public List<UInt32> list
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
	
	#region self_buf
	public class self_buf : Table.Binary
	{
		List<UInt32> m_list;
		
		public List<UInt32> list
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
	
	#region consume_item
	public class consume_item : Table.Binary
	{
		Byte   m_item_id;
		UInt32 m_item_num;
		
		public Byte itemId
		{
			get { return m_item_id; }
		}
		
		public UInt32 itemNum
		{
			get { return m_item_num; }
		}
		
		public override int Load(byte[] buffer, int index)
		{
			Table.Loader loader = new Table.Loader(ref buffer, index);
			loader.Load(ref m_item_id).Load(ref m_item_num);
			return loader.Size;
		}
	}
	#endregion
	
	#region consume_items
	public class consume_items : Table.Binary
	{
		List<consume_item> m_list;
		
		public List<consume_item> list
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
	
	UInt32        m_level_skill_id;
	UInt32        m_baseid;
	Byte          m_level;
	Table.String  m_name;
	Byte          m_type;
	UInt32        m_action_id;
	Byte          m_skill_ui_index;
	Byte          m_target_type;
	Byte          m_passtive_tri_condit;
	UInt32        m_condit_param;
	passive_buff  m_passive_buff;
	self_buf      m_self_buff;
	direct_buf    m_direct_buff;
	hit_buf       m_hit_buff;
	consume_items m_level_up_consume;
	UInt16        m_user;
	UInt32        m_skill_cd;
	UInt16        m_max_distance;
	
	public const UInt32 Version = 513308892;
	
	public UInt64 Key()
	{
		return m_level_skill_id;
	}
	
	public UInt32 levelSkillId
	{
		get { return m_level_skill_id; }
	}
	
	public UInt32 baseid
	{
		get { return m_baseid; }
	}
	
	public Byte level
	{
		get { return m_level; }
	}
	
	public string name
	{
		get { return m_name; }
	}
	
	public Byte type
	{
		get { return m_type; }
	}
	
	public UInt32 actionId
	{
		get { return m_action_id; }
	}
	
	public Byte skillUiIndex
	{
		get { return m_skill_ui_index; }
	}
	
	public Byte targetType
	{
		get { return m_target_type; }
	}
	
	public Byte passtiveTriCondit
	{
		get { return m_passtive_tri_condit; }
	}
	
	public UInt32 conditParam
	{
		get { return m_condit_param; }
	}
	
	public passive_buff passiveBuff
	{
		get { return m_passive_buff; }
	}
	
	public self_buf selfBuff
	{
		get { return m_self_buff; }
	}
	
	public direct_buf directBuff
	{
		get { return m_direct_buff; }
	}
	
	public hit_buf hitBuff
	{
		get { return m_hit_buff; }
	}
	
	public consume_items levelUpConsume
	{
		get { return m_level_up_consume; }
	}
	
	public UInt16 user
	{
		get { return m_user; }
	}
	
	public UInt32 skillCd
	{
		get { return m_skill_cd; }
	}
	
	public UInt16 maxDistance
	{
		get { return m_max_distance; }
	}
	
	public override int Load(byte[] buffer, int index)
	{
		Table.Loader loader = new Table.Loader(ref buffer, index);
		loader.Load(ref m_level_skill_id).Load(ref m_baseid).Load(ref m_level).Load(ref m_name).Load(ref m_type).Load(ref m_action_id).Load(ref m_skill_ui_index).Load(ref m_target_type).Load(ref m_passtive_tri_condit).Load(ref m_condit_param).Load(ref m_passive_buff).Load(ref m_self_buff).Load(ref m_direct_buff).Load(ref m_hit_buff).Load(ref m_level_up_consume).Load(ref m_user).Load(ref m_skill_cd).Load(ref m_max_distance);
		return loader.Size;
	}
}

// source: J 技能等级配置表.xls, sheet: Sheet1
public sealed class SkillLevelAttrManager : Table.Manager<SkillLevelAttr>
{
	private static readonly SkillLevelAttrManager ms_instance = new SkillLevelAttrManager();
	
	private SkillLevelAttrManager()
	{
	}
	
	public static SkillLevelAttrManager instance
	{
		get { return ms_instance; }
	}
	
	public string source
	{
		get { return "skill_level_attr.tbl"; }
	}
	
	public bool Load(string path)
	{
		Register();
		return Load(path, source, SkillLevelAttr.Version);
	}
	
	public SkillLevelAttr Find(UInt32 key)
	{
		return FindInternal(key);
	}
	
	#region new helper
	public static object NewSkillLevelAttr()
	{
		return new SkillLevelAttr();
	}
	public static object NewSkillLevelAttrpassive_buff()
	{
		return new SkillLevelAttr.passive_buff();
	}
	
	public static object NewSkillLevelAttrdirect_buf()
	{
		return new SkillLevelAttr.direct_buf();
	}
	
	public static object NewSkillLevelAttrhit_buf()
	{
		return new SkillLevelAttr.hit_buf();
	}
	
	public static object NewSkillLevelAttrself_buf()
	{
		return new SkillLevelAttr.self_buf();
	}
	
	public static object NewSkillLevelAttrconsume_item()
	{
		return new SkillLevelAttr.consume_item();
	}
	
	public static object NewSkillLevelAttrconsume_items()
	{
		return new SkillLevelAttr.consume_items();
	}
	
	private static void Register()
	{
		Table.NewHelper.Clear();
		Table.NewHelper.Register(typeof(SkillLevelAttr), NewSkillLevelAttr);
		Table.NewHelper.Register(typeof(SkillLevelAttr.passive_buff), NewSkillLevelAttrpassive_buff);
		Table.NewHelper.Register(typeof(SkillLevelAttr.direct_buf), NewSkillLevelAttrdirect_buf);
		Table.NewHelper.Register(typeof(SkillLevelAttr.hit_buf), NewSkillLevelAttrhit_buf);
		Table.NewHelper.Register(typeof(SkillLevelAttr.self_buf), NewSkillLevelAttrself_buf);
		Table.NewHelper.Register(typeof(SkillLevelAttr.consume_item), NewSkillLevelAttrconsume_item);
		Table.NewHelper.Register(typeof(SkillLevelAttr.consume_items), NewSkillLevelAttrconsume_items);
	}
	#endregion
}
