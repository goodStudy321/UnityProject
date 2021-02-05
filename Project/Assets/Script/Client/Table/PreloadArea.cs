// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: PreloadArea.prot

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;


public class PreloadArea : Table.Binary, Table.IKey
{
	#region UInts
	public class UInts : Table.Binary
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
	
	#region Strs
	public class Strs : Table.Binary
	{
		List<Table.String> m_list;
		
		public List<Table.String> list
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
	
	UInt32 m_id;
	UInts  m_wildIDs;
	UInts  m_npcIDs;
	Strs   m_ftNames;
	
	public const UInt32 Version = 1163467679;
	
	public UInt64 Key()
	{
		return m_id;
	}
	
	public UInt32 id
	{
		get { return m_id; }
	}
	
	public UInts wildIDs
	{
		get { return m_wildIDs; }
	}
	
	public UInts npcIDs
	{
		get { return m_npcIDs; }
	}
	
	public Strs ftNames
	{
		get { return m_ftNames; }
	}
	
	public override int Load(byte[] buffer, int index)
	{
		Table.Loader loader = new Table.Loader(ref buffer, index);
		loader.Load(ref m_id).Load(ref m_wildIDs).Load(ref m_npcIDs).Load(ref m_ftNames);
		return loader.Size;
	}
}

// source: Q 区域预加载.xls, sheet: Sheet1
public sealed class PreloadAreaManager : Table.Manager<PreloadArea>
{
	private static readonly PreloadAreaManager ms_instance = new PreloadAreaManager();
	
	private PreloadAreaManager()
	{
	}
	
	public static PreloadAreaManager instance
	{
		get { return ms_instance; }
	}
	
	public string source
	{
		get { return "preloadarea.tbl"; }
	}
	
	public bool Load(string path)
	{
		Register();
		return Load(path, source, PreloadArea.Version);
	}
	
	public PreloadArea Find(UInt32 key)
	{
		return FindInternal(key);
	}
	
	#region new helper
	public static object NewPreloadArea()
	{
		return new PreloadArea();
	}
	public static object NewPreloadAreaUInts()
	{
		return new PreloadArea.UInts();
	}
	
	public static object NewPreloadAreaStrs()
	{
		return new PreloadArea.Strs();
	}
	
	private static void Register()
	{
		Table.NewHelper.Clear();
		Table.NewHelper.Register(typeof(PreloadArea), NewPreloadArea);
		Table.NewHelper.Register(typeof(PreloadArea.UInts), NewPreloadAreaUInts);
		Table.NewHelper.Register(typeof(PreloadArea.Strs), NewPreloadAreaStrs);
	}
	#endregion
}

