// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: MagicWeaponInfo.prot

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;


public class MagicWeaponInfo : Table.Binary, Table.IKey
{
	#region array
	public class array : Table.Binary
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
	
	UInt32       m_id;
	Table.String m_name;
	UInt16       m_model_id;
	UInt16       m_ui_model_id;
	Byte         m_root;
	Table.String m_icon_path;
	
	public const UInt32 Version = 695226156;
	
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
	
	public UInt16 modelId
	{
		get { return m_model_id; }
	}
	
	public UInt16 uiModelId
	{
		get { return m_ui_model_id; }
	}
	
	public Byte root
	{
		get { return m_root; }
	}
	
	public string iconPath
	{
		get { return m_icon_path; }
	}
	
	public override int Load(byte[] buffer, int index)
	{
		Table.Loader loader = new Table.Loader(ref buffer, index);
		loader.Load(ref m_id).Load(ref m_name).Load(ref m_model_id).Load(ref m_ui_model_id).Load(ref m_root).Load(ref m_icon_path);
		return loader.Size;
	}
}

// source: F 法宝基础表.xls, sheet: Sheet1
public sealed class MagicWeaponInfoManager : Table.Manager<MagicWeaponInfo>
{
	private static readonly MagicWeaponInfoManager ms_instance = new MagicWeaponInfoManager();
	
	private MagicWeaponInfoManager()
	{
	}
	
	public static MagicWeaponInfoManager instance
	{
		get { return ms_instance; }
	}
	
	public string source
	{
		get { return "magicweaponinfo.tbl"; }
	}
	
	public bool Load(string path)
	{
		Register();
		return Load(path, source, MagicWeaponInfo.Version);
	}
	
	public MagicWeaponInfo Find(UInt32 key)
	{
		return FindInternal(key);
	}
	
	#region new helper
	public static object NewMagicWeaponInfo()
	{
		return new MagicWeaponInfo();
	}
	public static object NewMagicWeaponInfoarray()
	{
		return new MagicWeaponInfo.array();
	}
	
	private static void Register()
	{
		Table.NewHelper.Clear();
		Table.NewHelper.Register(typeof(MagicWeaponInfo), NewMagicWeaponInfo);
		Table.NewHelper.Register(typeof(MagicWeaponInfo.array), NewMagicWeaponInfoarray);
	}
	#endregion
}

