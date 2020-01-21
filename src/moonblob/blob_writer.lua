local ffi = require('ffi')
local band, bnot, shr, shl = bit.band, bit.bnot, bit.rshift, bit.lshift
local _byteOrder, _parseByteOrder, _Union
local _tags, _getTag, _taggedReaders, _taggedWriters, _packMap, _unpackMap, _arrayTypeMap
local BlobWriter
do
  local _class_0
  local _base_0 = {
    write = function(self, value)
      return self:_writeTagged(value)
    end,
    number = function(self, value)
      self._union.f64 = value
      return self:u32(self._union.u32[0]):u32(self._union.u32[1])
    end,
    bool = function(self, value)
      return self:u8(value and 1 or 0)
    end,
    string = function(self, value)
      local length = #value
      return self:vu32(length):raw(value, length)
    end,
    u8 = function(self, value)
      if self._length + 1 > self._size then
        self:_grow(1)
      end
      self._data[self._length] = value
      self._length = self._length + 1
      return self
    end,
    s8 = function(self, value)
      self._union.s8[0] = value
      return self:u8(self._union.u8[0])
    end,
    u16 = function(self, value)
      local len = self._length
      if len + 2 > self._size then
        self:_grow(2)
      end
      self._data[len], self._data[len + 1] = self._orderBytes(band(value, 2 ^ 8 - 1), shr(value, 8))
      self._length = self._length + 2
      return self
    end,
    s16 = function(self, value)
      self._union.s16[0] = value
      return self:u16(self._union.u16[0])
    end,
    u32 = function(self, value)
      local len = self._length
      if len + 4 > self._size then
        self:_grow(4)
      end
      local w1, w2 = self._orderBytes(band(value, 2 ^ 16 - 1), shr(value, 16))
      local b1, b2 = self._orderBytes(band(w1, 2 ^ 8 - 1), shr(w1, 8))
      local b3, b4 = self._orderBytes(band(w2, 2 ^ 8 - 1), shr(w2, 8))
      self._data[len], self._data[len + 1], self._data[len + 2], self._data[len + 3] = b1, b2, b3, b4
      self._length = self._length + 4
      return self
    end,
    s32 = function(self, value)
      self._union.s32[0] = value
      return self:u32(self._union.u32[0])
    end,
    vu32 = function(self, value)
      if not (value < 2 ^ 32) then
        error("Exceeded u32 value limits")
      end
      for i = 7, 28, 7 do
        local mask, shift = 2 ^ i - 1, i - 7
        if value < 2 ^ i then
          return self:u8(shr(band(value, mask), shift))
        end
        self:u8(shr(band(value, mask), shift) + 0x80)
      end
      return self:u8(shr(band(value, 0xf0000000), 28))
    end,
    vs32 = function(self, value)
      if not (value < 2 ^ 31 and value >= -2 ^ 31) then
        error("Exceeded s32 value limits")
      end
      local signBit
      signBit, value = value < 0 and 1 or 0, math.abs(value)
      if value < 2 ^ 6 then
        return self:u8(shl(band(value, 0x3f), 1) + signBit)
      end
      self:u8(shl(band(value, 0x3f), 1) + signBit + 0x80)
      for i = 13, 27, 7 do
        local mask, shift = 2 ^ i - 1, i - 7
        if value < 2 ^ i then
          return self:u8(shr(band(value, mask), shift))
        end
        self:u8(shr(band(value, mask), shift) + 0x80)
      end
      return self:u8(shr(band(value, 0xf8000000), 27))
    end,
    u64 = function(self, value)
      self._union.u64 = value
      local a, b = self._orderBytes(self._union.u32[0], self._union.u32[1])
      return self:u32(a):u32(b)
    end,
    s64 = function(self, value)
      self._union.s64 = value
      local a, b = self._orderBytes(self._union.u32[0], self._union.u32[1])
      return self:u32(a):u32(b)
    end,
    f32 = function(self, value)
      self._union.f32[0] = value
      return self:u32(self._union.u32[0])
    end,
    f64 = function(self, value)
      return self:number(value)
    end,
    raw = function(self, value, length)
      length = length or #value
      local makeRoom = (self._size - self._length) - length
      if makeRoom < 0 then
        self:_grow(math.abs(makeRoom))
      end
      ffi.copy(ffi.cast('uint8_t*', self._data + self._length), value, length)
      self._length = self._length + length
      return self
    end,
    cstring = function(self, value)
      return self:raw(value):u8(0)
    end,
    table = function(self, value)
      return self:_writeTable(value, { })
    end,
    array = function(self, valueType, values, writeLength)
      if writeLength == nil then
        writeLength = true
      end
      local writer = _arrayTypeMap[valueType]
      if not (writer) then
        error("Invalid array type <" .. tostring(valueType) .. ">")
      end
      if writeLength then
        self:vu32(#values)
      end
      for _index_0 = 1, #values do
        local v = values[_index_0]
        writer(self, v)
      end
      return self
    end,
    pack = function(self, format, ...)
      local data, index, len = {
        ...
      }, 1, nil
      local limit = select('#', ...)
      local _writeRaw
      _writeRaw = function()
        local l = tonumber(table.concat(len))
        if not (l) then
          error("Invalid string length specification: " .. tostring(table.concat(len)))
        end
        if not (l < 2 ^ 32) then
          error("Maximum string length exceeded")
        end
        self:raw(data[index], l)
        index, len = index + 1, nil
      end
      format:gsub('.', function(c)
        if len then
          if tonumber(c) then
            table.insert(len, c)
          else
            if not (index <= limit) then
              error("Number of arguments to pack does not match format specifiers")
            end
            _writeRaw()
          end
        end
        if not (len) then
          local writer = _packMap[c]
          if not (writer) then
            error("Invalid data type specifier: " .. tostring(c))
          end
          if c == 'c' then
            len = { }
          else
            if not (index <= limit) then
              error("Number of arguments to pack does not match format specifiers")
            end
            if writer(self, data[index]) then
              index = index + 1
            end
          end
        end
      end)
      if len then
        _writeRaw()
      end
      return self
    end,
    clear = function(self, size)
      self._length = 0
      if size then
        self._data = nil
        self:_allocate(size)
      end
      return self
    end,
    tostring = function(self)
      return ffi.string(self._data, self._length)
    end,
    length = function(self)
      return self._length
    end,
    size = function(self)
      return self._size
    end,
    vu32size = function(self, value)
      if not (value < 2 ^ 32) then
        error("Exceeded u32 value limits")
      end
      if value < 2 ^ 7 then
        return 1
      end
      if value < 2 ^ 14 then
        return 2
      end
      if value < 2 ^ 21 then
        return 3
      end
      if value < 2 ^ 28 then
        return 4
      end
      return 5
    end,
    vs32size = function(self, value)
      if not (value < 2 ^ 31 and value >= -2 ^ 31) then
        error("Exceeded s32 value limits")
      end
      value = math.abs(value) + 1
      if value < 2 ^ 7 then
        return 1
      end
      if value < 2 ^ 14 then
        return 2
      end
      if value < 2 ^ 21 then
        return 3
      end
      if value < 2 ^ 28 then
        return 4
      end
      return 5
    end,
    setByteOrder = function(self, byteOrder)
      self._orderBytes = _byteOrder[_parseByteOrder(byteOrder)]
      return self
    end,
    _allocate = function(self, size)
      local data
      if size > 0 then
        data = ffi.new('uint8_t[?]', size)
        if self._data then
          ffi.copy(data, self._data, self._length)
        end
      end
      self._data, self._size = data, size
      self._length = math.min(size, self._length)
    end,
    _grow = function(self, minimum)
      if minimum == nil then
        minimum = 0
      end
      local newSize = math.max(self._size + minimum, math.floor(math.max(1, self._size * 1.5) + .5))
      return self:_allocate(newSize)
    end,
    _writeTable = function(self, t, stack)
      if stack == nil then
        stack = { }
      end
      if stack[t] then
        error("Cycle detected; can't serialize table")
      end
      stack[t] = true
      for key, value in pairs(t) do
        self:_writeTaggedPair(key, value, stack)
      end
      stack[t] = nil
      return self:u8(_tags.stop)
    end,
    _writeTaggedPair = function(self, key, value, stack)
      if type(value) == 'function' then
        return self
      end
      self:_writeTagged(key, stack)
      return self:_writeTagged(value, stack)
    end,
    _writeTagged = function(self, value, stack)
      local tag = _getTag(value)
      if not (tag) then
        error("Can't write values of type '" .. tostring(type(value)) .. "'")
      end
      self:u8(tag)
      return _taggedWriters[tag](self, value, stack)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, sizeOrByteOrder, size)
      self._union = _Union()
      self._length, self._size = 0, 0
      local byteOrder = type(sizeOrByteOrder) == 'string' and sizeOrByteOrder or nil
      size = type(sizeOrByteOrder) == 'number' and sizeOrByteOrder or size
      self:setByteOrder(byteOrder)
      return self:_allocate(size or 1024)
    end,
    __base = _base_0,
    __name = "BlobWriter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BlobWriter = _class_0
end
_byteOrder = {
  le = function(v1, v2)
    return v1, v2
  end,
  be = function(v1, v2)
    return v2, v1
  end
}
_tags = {
  stop = 0,
  number = 1,
  string = 2,
  table = 3,
  [true] = 4,
  [false] = 5,
  zero = 6,
  vs32 = 7,
  vu32 = 8,
  vs64 = 9,
  vu64 = 10
}
do
  _taggedWriters = {
    BlobWriter.number,
    BlobWriter.string,
    BlobWriter._writeTable,
    function(self)
      return self
    end,
    function(self)
      return self
    end,
    function(self)
      return self
    end,
    BlobWriter.vs32,
    BlobWriter.vu32,
    function(self, val)
      self._union.s64 = val
      return self:vs32(self._union.s32[0]):vs32(self._union.s32[1])
    end,
    function(self, val)
      self._union.u64 = val
      return self:vu32(self._union.u32[0]):vs32(self._union.u32[1])
    end
  }
  _arrayTypeMap = {
    s8 = BlobWriter.s8,
    u8 = BlobWriter.u8,
    s16 = BlobWriter.s16,
    u16 = BlobWriter.u16,
    s32 = BlobWriter.s32,
    u32 = BlobWriter.u32,
    s64 = BlobWriter.s64,
    u64 = BlobWriter.u64,
    vs32 = BlobWriter.vs32,
    vu32 = BlobWriter.vu32,
    f32 = BlobWriter.f32,
    f64 = BlobWriter.f64,
    number = BlobWriter.number,
    string = BlobWriter.string,
    cstring = BlobWriter.cstring,
    bool = BlobWriter.bool,
    table = BlobWriter.table
  }
  _packMap = {
    b = BlobWriter.s8,
    B = BlobWriter.u8,
    h = BlobWriter.s16,
    H = BlobWriter.u16,
    l = BlobWriter.s32,
    L = BlobWriter.u32,
    v = BlobWriter.vs32,
    V = BlobWriter.vu32,
    q = BlobWriter.s64,
    Q = BlobWriter.u64,
    f = BlobWriter.f32,
    d = BlobWriter.number,
    n = BlobWriter.number,
    c = BlobWriter.raw,
    s = BlobWriter.string,
    z = BlobWriter.cstring,
    t = BlobWriter.table,
    y = BlobWriter.bool,
    ['<'] = function(self)
      return nil, self:setByteOrder('<')
    end,
    ['>'] = function(self)
      return nil, self:setByteOrder('>')
    end,
    ['='] = function(self)
      return nil, self:setByteOrder('=')
    end
  }
end
_parseByteOrder = function(endian)
  local _exp_0 = endian
  if nil == _exp_0 or '=' == _exp_0 or 'host' == _exp_0 then
    endian = ffi.abi('le') and 'le' or 'be'
  elseif '<' == _exp_0 or 'le' == _exp_0 then
    endian = 'le'
  elseif '>' == _exp_0 or 'be' == _exp_0 then
    endian = 'be'
  else
    error("Invalid byteOrder identifier: " .. tostring(endian))
  end
  return endian
end
_getTag = function(value)
  local t = type(value)
  local _exp_0 = t
  if 'boolean' == _exp_0 then
    return _tags[value]
  elseif 'number' == _exp_0 then
    if math.floor(value) ~= value then
      return _tags.number
    end
    if value == 0 then
      return _tags.zero
    end
    if value > 0 then
      if value < 2 ^ 32 then
        return _tags.vu32
      end
      return _tags.vu64
    end
    if value >= -2 ^ 31 then
      return _tags.vs32
    end
    return _tags.vs64
  end
  return _tags[t]
end
_Union = ffi.typeof([[	union {
		  int8_t s8[8];
		 uint8_t u8[8];
		 int16_t s16[4];
		uint16_t u16[4];
		 int32_t s32[2];
		uint32_t u32[2];
		   float f32[2];
		 int64_t s64;
		uint64_t u64;
		  double f64;
	}
]])
return BlobWriter
