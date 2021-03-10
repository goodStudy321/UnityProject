// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: InitDesCfg.prot

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;


public class InitDesCfg : Table.Binary, Table.IKey
{
	UInt16       m_id;
	Table.String m_title;
	Table.String m_des;
	
	public const UInt32 Version = 1679255978;
	
	public UInt64 Key()
	{
		return m_id;
	}
	
	public UInt16 id
	{
		get { return m_id; }
	}
	
	public string title
	{
		get { return m_title; }
	}
	
	public string des
	{
		get { return m_des; }
	}
	
	public override int Load(byte[] buffer, int index)
	{
		Table.Loader loader = new Table.Loader(ref buffer, index);
		loader.Load(ref m_id).Load(ref m_title).Load(ref m_des);
		return loader.Size;
	}
}

// source: C 初始加载游戏文本.xls, sheet: Sheet1
public sealed class InitDesCfgManager : Table.Manager<InitDesCfg>
{
	private static readonly InitDesCfgManager ms_instance = new InitDesCfgManager();
	
	private InitDesCfgManager()
	{
	}
	
	public static InitDesCfgManager instance
	{
		get { return ms_instance; }
	}
	
	public string source
	{
		get { return "initdescfg.tbl"; }
	}
	
	public bool Load(string path)
	{
		Register();
		return Load(path, source, InitDesCfg.Version);
	}
	
	public InitDesCfg Find(UInt16 key)
	{
		return FindInternal(key);
	}
	
	#region new helper
	public static object NewInitDesCfg()
	{
		return new InitDesCfg();
	}
	
	private static void Register()
	{
		Table.NewHelper.Clear();
		Table.NewHelper.Register(typeof(InitDesCfg), NewInitDesCfg);
	}
	#endregion
}

