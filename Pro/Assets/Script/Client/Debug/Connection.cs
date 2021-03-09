using System;
using System.IO;


public class Connection
{
    public delegate void EventHandle(Object param);
    public delegate int Handle(byte[] data, int size);

    public int type_id = 0;

    public const int MAX_BUFFER_SIZE = 1024;
    public const int MAX_PACKET_SIZE = MAX_BUFFER_SIZE - 24;

    private Handle m_handle = null;
    private EventHandle m_connected = null;
    private EventHandle m_disconnect = null;

    protected int m_total_recv_length = 0;
    protected int m_total_send_length = 0;
    protected byte[] m_buffer = new byte[MAX_BUFFER_SIZE];

    protected Connection(Handle handle)
    {
        m_handle = handle;
    }

    protected Handle handle
    {
        get { return m_handle; }
    }

    public EventHandle connectHandle
    {
        get { return m_connected; }
        set { m_connected = value; }
    }

    public EventHandle disconnectHandle
    {
        get { return m_disconnect; }
        set { m_disconnect = value; }
    }

    public virtual void Close()
    {
    }

    public virtual void Break()
    {
    }

    public virtual bool Connect(string hostname, int port, bool last)
    {
        return false;
    }

    public virtual bool Send(byte[] buffer, int size)
    {
        return false;
    }

    protected void OnConnected()
    {
        if (m_connected != null)
            m_connected(true);
    }

    protected void OnConnectedFailed()
    {
        if (m_connected != null)
            m_connected(false);
    }

    protected void OnDisconnected(Object param)
    {
        if (m_disconnect != null)
            m_disconnect(param);
    }
}