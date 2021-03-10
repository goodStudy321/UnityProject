// Generated by the Table Description Language compiler.  DO NOT EDIT!
// source: scene_trigger.prot

#ifndef _TDL_SCENE_TRIGGER_H_
#define _TDL_SCENE_TRIGGER_H_

#include "table_utility.h"

class SceneTrigger;
class SceneTriggerManager;


// ===================================================================
#pragma pack( 1 )
class SceneTrigger
{
public:
	// nested types ----------------------------------------------------
	class vector3
	{
	public:
		int32 x() const;
		int32 z() const;
		
	private:
		int32 m_x;
		int32 m_z;
	};
	
	typedef uint32	KeyType;
	
	static const uint32 Version = 1375938042;
	
	uint32 Key() const;
	
	uint32 id() const;
	const char* triggername() const;
	const vector3& left() const;
	const vector3& right() const;
	uint8 times() const;
	uint8 premisetimes() const;
	
private:
	uint32  m_ID;
	int     m_triggerName;
	vector3 m_left;
	vector3 m_right;
	uint8   m_times;
	uint8   m_premiseTimes;
};
#pragma pack()

// -------------------------------------------------------------------
// source: C 场景Trigger配置表.xls, sheet: Sheet1
class SceneTriggerManager : public Table::Manager, public Singleton< SceneTriggerManager >
{
public:
	int Size() const;
	const char* Source() const;
	bool Load( const char *path );
	bool Reload( const char *path );
	
	const SceneTrigger& Get( int index ) const;
	const SceneTrigger* Find( const uint32 key ) const;
	
private:
	friend class Singleton< SceneTriggerManager >;
	typedef Table::RepeatField< SceneTriggerManager, SceneTrigger >	SceneTriggerArray;
	
	SceneTriggerManager();
	~SceneTriggerManager();
	
private:
	const SceneTriggerArray *m_array;
};


// ===================================================================
// inline methords of SceneTrigger
inline uint32 SceneTrigger::Key() const
{
	return Combiner< uint32 >::Combine( m_ID );
}

inline uint32 SceneTrigger::id() const
{
	return m_ID;
}

inline const char* SceneTrigger::triggername() const
{
	return SceneTriggerManager::Instance().String( m_triggerName );
}

inline const SceneTrigger::vector3& SceneTrigger::left() const
{
	return m_left;
}

inline const SceneTrigger::vector3& SceneTrigger::right() const
{
	return m_right;
}

inline uint8 SceneTrigger::times() const
{
	return m_times;
}

inline uint8 SceneTrigger::premisetimes() const
{
	return m_premiseTimes;
}


// inline methords of SceneTrigger::vector3
inline int32 SceneTrigger::vector3::x() const
{
	return m_x;
}

inline int32 SceneTrigger::vector3::z() const
{
	return m_z;
}


// inline methords of SceneTriggerManager
inline SceneTriggerManager::SceneTriggerManager()
	: m_array( NULL )
{
}

inline SceneTriggerManager::~SceneTriggerManager()
{
}

inline int SceneTriggerManager::Size() const
{
	assert( m_array );
	return m_array->Size();
}

inline const char* SceneTriggerManager::Source() const
{
	return "scene_trigger.tbl";
}

inline bool SceneTriggerManager::Load( const char *path )
{
	const char *data = Table::Manager::Load( path, Source() );
	if( !data )
		return false;
		
	m_array = (const SceneTriggerArray *)data;
	return true;
}

inline bool SceneTriggerManager::Reload( const char *path )
{
	const char *data = Table::Manager::Reload( path, Source() );
	if( !data )
		return false;
		
	m_array = (const SceneTriggerArray *)data;
	return true;
}

inline const SceneTrigger& SceneTriggerManager::Get( int index ) const
{
	assert( m_array );
	return m_array->Get( index );
}

inline const SceneTrigger* SceneTriggerManager::Find( uint32 key ) const
{
	assert( m_array );
	return BinarySerach< SceneTrigger >( Data( m_array->Offset() ), m_array->Size(), key );
}


#endif