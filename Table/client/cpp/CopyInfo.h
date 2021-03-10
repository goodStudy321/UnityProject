// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: CopyInfo.prot

#ifndef _TDL_COPYINFO_H_
#define _TDL_COPYINFO_H_

#include "table_utility.h"

class CopyInfo;
class CopyInfoManager;


// ===================================================================
#pragma pack( 1 )
class CopyInfo
{
public:
	// nested types ----------------------------------------------------
	class item
	{
	public:
		int32 id() const;
		int32 num() const;
		
	private:
		int32 m_id;
		int32 m_num;
	};
	
	// -------------------------------------------------------------------
	typedef Table::RepeatField< CopyInfoManager, item >	item_list;
	
	typedef uint32	KeyType;
	
	static const uint32 Version = 1461901223;
	
	uint32 Key() const;
	
	uint32 base_id() const;
	const char* name() const;
	uint8 copy_type() const;
	const char* three_name() const;
	const char* des() const;
	const char* icon() const;
	uint8 complete_type() const;
	uint8 enter_num() const;
	uint8 end_downcount() const;
	uint8 is_mount() const;
	uint8 is_pk() const;
	uint8 enter_level() const;
	uint8 player_num_limit() const;
	const char* value() const;
	const item_list& show_items() const;
	
private:
	uint32    m_base_id;
	int       m_name;
	uint8     m_copy_type;
	int       m_three_name;
	int       m_des;
	int       m_icon;
	uint8     m_complete_type;
	uint8     m_enter_num;
	uint8     m_end_downcount;
	uint8     m_is_mount;
	uint8     m_is_pk;
	uint8     m_enter_level;
	uint8     m_player_num_limit;
	int       m_value;
	item_list m_show_Items;
};
#pragma pack()

// -------------------------------------------------------------------
// source: F 副本.xls, sheet: Sheet1
class CopyInfoManager : public Table::Manager, public Singleton< CopyInfoManager >
{
public:
	int Size() const;
	const char* Source() const;
	bool Load( const char *path );
	bool Reload( const char *path );
	
	const CopyInfo& Get( int index ) const;
	const CopyInfo* Find( const uint32 key ) const;
	
private:
	friend class Singleton< CopyInfoManager >;
	typedef Table::RepeatField< CopyInfoManager, CopyInfo >	CopyInfoArray;
	
	CopyInfoManager();
	~CopyInfoManager();
	
private:
	const CopyInfoArray *m_array;
};


// ===================================================================
// inline methords of CopyInfo
inline uint32 CopyInfo::Key() const
{
	return Combiner< uint32 >::Combine( m_base_id );
}

inline uint32 CopyInfo::base_id() const
{
	return m_base_id;
}

inline const char* CopyInfo::name() const
{
	return CopyInfoManager::Instance().String( m_name );
}

inline uint8 CopyInfo::copy_type() const
{
	return m_copy_type;
}

inline const char* CopyInfo::three_name() const
{
	return CopyInfoManager::Instance().String( m_three_name );
}

inline const char* CopyInfo::des() const
{
	return CopyInfoManager::Instance().String( m_des );
}

inline const char* CopyInfo::icon() const
{
	return CopyInfoManager::Instance().String( m_icon );
}

inline uint8 CopyInfo::complete_type() const
{
	return m_complete_type;
}

inline uint8 CopyInfo::enter_num() const
{
	return m_enter_num;
}

inline uint8 CopyInfo::end_downcount() const
{
	return m_end_downcount;
}

inline uint8 CopyInfo::is_mount() const
{
	return m_is_mount;
}

inline uint8 CopyInfo::is_pk() const
{
	return m_is_pk;
}

inline uint8 CopyInfo::enter_level() const
{
	return m_enter_level;
}

inline uint8 CopyInfo::player_num_limit() const
{
	return m_player_num_limit;
}

inline const char* CopyInfo::value() const
{
	return CopyInfoManager::Instance().String( m_value );
}

inline const CopyInfo::item_list& CopyInfo::show_items() const
{
	return m_show_Items;
}


// inline methords of CopyInfo::item
inline int32 CopyInfo::item::id() const
{
	return m_id;
}

inline int32 CopyInfo::item::num() const
{
	return m_num;
}


// inline methords of CopyInfoManager
inline CopyInfoManager::CopyInfoManager()
	: m_array( NULL )
{
}

inline CopyInfoManager::~CopyInfoManager()
{
}

inline int CopyInfoManager::Size() const
{
	assert( m_array );
	return m_array->Size();
}

inline const char* CopyInfoManager::Source() const
{
	return "copyinfo.tbl";
}

inline bool CopyInfoManager::Load( const char *path )
{
	const char *data = Table::Manager::Load( path, Source() );
	if( !data )
		return false;
		
	m_array = (const CopyInfoArray *)data;
	return true;
}

inline bool CopyInfoManager::Reload( const char *path )
{
	const char *data = Table::Manager::Reload( path, Source() );
	if( !data )
		return false;
		
	m_array = (const CopyInfoArray *)data;
	return true;
}

inline const CopyInfo& CopyInfoManager::Get( int index ) const
{
	assert( m_array );
	return m_array->Get( index );
}

inline const CopyInfo* CopyInfoManager::Find( uint32 key ) const
{
	assert( m_array );
	return BinarySerach< CopyInfo >( Data( m_array->Offset() ), m_array->Size(), key );
}


#endif