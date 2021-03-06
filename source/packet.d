module pnet.packet;

TTo qcast(TTo, TFrom)(TFrom from)
{
  return cast(TTo)from;
}

size_t sumStringSize(dstring[] r, size_t factor = 1, size_t extra = 0)
{
    size_t value;

    foreach (s; r)
    {
        value += (s.length * factor) + extra;
    }

    return value + (r.length * 2);
}

size_t sumStringSizeSeparate(dstring[] r, size_t factor = 1, size_t extra = 0)
{
    size_t value;

    foreach (s; r)
    {
        value += (s.length * factor) + extra;
    }

    return value;
}

class Packet
{
  private:
  ubyte[] _buffer;
  size_t _readOffset;
  size_t _writeOffset;
  size_t _size;
  ushort _id;

  public:
  ubyte[] finalize()
  {
    return _buffer.dup;
  }

  final:
  this(ubyte[] buffer)
  {
    _buffer = buffer;
    _size = read!ushort;
    _id = read!ushort;
  }

  this(ushort size, ushort id)
  {
    _size = size;

    _buffer = new ubyte[_size];
    write!ushort(_size);
    write!ushort(id);
  }

  @property
  {
    ushort id()
    {
      return _id;
    }

    size_t physicalSize()
    {
      return _buffer ? _buffer.length : 0;
    }

    ushort virtualSize()
    {
      return _size;
    }
  }

  T read(T)(size_t size = 0)
  {
    static if (is(T == bool))
    {
      return read!ubyte;
    }
    else static if (is(T == dstring))
    {
      if (!size)
      {
        size = read!ushort;
      }

      if (size)
      {
        auto byteSize = (size * uint.sizeof);
        auto buffer = _buffer[_readOffset .. byteSize];
        dstring value = cast(uint[])cast(ubyte[])buffer;

        _readOffset += byteSize;
      }

      return value;
    }
    else static if (is(T == string) || is(T == wstring))
    {
      static assert(0);
    }
    else
    {
      T value = (*cast(T*)(_buffer.ptr + _readOffset));
      _readOffset += T.sizeof;

      return value;
    }
  }

  void write(T, bool dynamicString = true)(T value)
  {
    static if (is(T == bool))
    {
      return write!ubyte(0);
    }
    else static if (is(T == dstring))
    {
      size_t length = value ? value.length : 0;

      static if (dynamicString)
      {
        (*cast(ushort*)(_buffer.ptr + _writeOffset)) = length;
      }

      if (length)
      {
        import std.string : representation;

        auto buffer = value.representation;
        auto bytes = cast(ubyte[])buffer;

        foreach (b; bytes)
        {
          (*cast(ubyte*)(_buffer.ptr + _writeOffset)) = b;
          _writeOffset++;
        }
      }
    }
    else static if (is(T == string) || is(T == wstring))
    {
      static assert(0);
    }
    else
    {
      (*cast(T*)(_buffer.ptr + _writeOffset)) = value;
      _writeOffset += T.sizeof;

      return value;
    }
  }

  void skip(size_t amount)
  {
    _readOffset += amount;
  }

  void fill(size_t amount)
  {
    _writeOffset += amount;
  }

  void expand(size_t amount)
  {
    _size += cast(ushort)amount;

    _buffer ~= new ubyte[amount];

    (*cast(ushort*)(_buffer.ptr)) = _size;
  }
}
