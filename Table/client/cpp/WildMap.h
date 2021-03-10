// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: WildMap.prot

#ifndef _TDL_WILDMAP_H_
#define _TDL_WILDMAP_H_

#include "table_utility.h"

class WildMap;
class WildMapManager;


// ===================================================================
#pragma pack( 1 )
class WildMap
{
public:
	// nested types ----------------------------------------------------
	class vecto2
	{
	public:
		int32 x() const;
		int32 z() const;
		
	private:
		int32 m_x;
		int32 m_z;
	};
	
	typedef uint32	KeyType;
	
	static const uint32 Version = 625692780;
	
	uint32 Key() const;
	
	uint32 id() const;
	uint32 monster_id() const;
	uint32 collection_id() const;
	const vecto2& left_pos() const;
	const vecto2& right_pos() const;
	
private:
	uint32 m_id;
	uint32 m_monster_id;
	uint32 m_collection_id;
	vecto2 m_left_pos;
	vecto2 m_right_pos;
};
#pragma pack()

// -------------------------------------------------------------------
// source: Y 野外地图.xls, sheet: 刷新列表
class WildMapManager : public Table::Manager, public Singleton< WildMapManager >
{
public:
	int Size() const;
	const char* Source() const;
	bool Load( const char *path );
	bool Reload( const char *path );
	
	const WildMap& Get( int index ) const;
	const WildMap* Find( const uint32 key ) const;
	
private:
	friend class Singleton< WildMapManager >;
	typedef Table::RepeatField< WildMapManager, WildMap >	WildMapArray;
	
	WildMapManager();
	~WildMapManager();
	
private:
	const WildMapArray *m_array;
};


// ===================================================================
// inline methords of WildMap
inline uint32 WildMap::Key() const
{
	return Combiner< uint32 >::Combine( m_id );
}

inline uint32 WildMap::id() const
{
	return m_id;
}

inline uint32 WildMap::monster_id() const
{
	return m_monster_id;
}

inline uint32 WildMap::collection_id() const
{
	return m_collection_id;
}

inline const WildMap::vecto2& WildMap::left_pos() const
{
	return m_left_pos;
}

inline const WildMap::vecto2& WildMap::right_pos() const
{
	return m_right_pos;
}


// inline methords of WildMap::vecto2
inline int32 WildMap::vecto2::x() const
{
	return m_x;
}

inline int32 WildMap::vecto2::z() const
{
	return m_z;
}


// inline methords of WildMapManager
inline WildMapManager::WildMapManager()
	: m_array( NULL )
{
}

inline WildMapManager::~WildMapManager()
{
}

inline int WildMapManager::Size() const
{
	assert( m_array );
	return m_array->Size();
}

inline const char* WildMapManager::Source() const
{
	return "wildmap.tbl";
}

inline bool WildMapManager::Load( const char *path )
{
	const char *data = Table::Manager::Load( path, Source() );
	if( !data )
		return false;
		
	m_array = (const WildMapArray *)data;
	return true;
}

inline bool WildMapManager::Reload( const char *path )
{
	const char *data = Table::Manager::Reload( path, Source() );
	if( !data )
		return false;
		
	m_array = (const WildMapArray *)data;
	return true;
}

inline const WildMap& WildMapManager::Get( int index ) const
{
	assert( m_array );
	return m_array->Get( index );
}

inline const WildMap* WildMapManager::Find( uint32 key ) const
{
	assert( m_array );
	return BinarySerach< WildMap >( Data( m_array->Offset() ), m_array->Size(), key );
}


#endif