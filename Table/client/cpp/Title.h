// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: Title.prot

#ifndef _TDL_TITLE_H_
#define _TDL_TITLE_H_

#include "table_utility.h"

class Title;
class TitleManager;


// ===================================================================
#pragma pack( 1 )
class Title
{
public:
	// nested types ----------------------------------------------------
	typedef uint32	KeyType;
	
	static const uint32 Version = 493378320;
	
	uint32 Key() const;
	
	uint32 id() const;
	const char* prefab() const;
	
private:
	uint32 m_id;
	int    m_prefab;
};
#pragma pack()

// -------------------------------------------------------------------
// source: C 称号配置表.xls, sheet: Sheet1
class TitleManager : public Table::Manager, public Singleton< TitleManager >
{
public:
	int Size() const;
	const char* Source() const;
	bool Load( const char *path );
	bool Reload( const char *path );
	
	const Title& Get( int index ) const;
	const Title* Find( const uint32 key ) const;
	
private:
	friend class Singleton< TitleManager >;
	typedef Table::RepeatField< TitleManager, Title >	TitleArray;
	
	TitleManager();
	~TitleManager();
	
private:
	const TitleArray *m_array;
};


// ===================================================================
// inline methords of Title
inline uint32 Title::Key() const
{
	return Combiner< uint32 >::Combine( m_id );
}

inline uint32 Title::id() const
{
	return m_id;
}

inline const char* Title::prefab() const
{
	return TitleManager::Instance().String( m_prefab );
}


// inline methords of TitleManager
inline TitleManager::TitleManager()
	: m_array( NULL )
{
}

inline TitleManager::~TitleManager()
{
}

inline int TitleManager::Size() const
{
	assert( m_array );
	return m_array->Size();
}

inline const char* TitleManager::Source() const
{
	return "title.tbl";
}

inline bool TitleManager::Load( const char *path )
{
	const char *data = Table::Manager::Load( path, Source() );
	if( !data )
		return false;
		
	m_array = (const TitleArray *)data;
	return true;
}

inline bool TitleManager::Reload( const char *path )
{
	const char *data = Table::Manager::Reload( path, Source() );
	if( !data )
		return false;
		
	m_array = (const TitleArray *)data;
	return true;
}

inline const Title& TitleManager::Get( int index ) const
{
	assert( m_array );
	return m_array->Get( index );
}

inline const Title* TitleManager::Find( uint32 key ) const
{
	assert( m_array );
	return BinarySerach< Title >( Data( m_array->Offset() ), m_array->Size(), key );
}


#endif