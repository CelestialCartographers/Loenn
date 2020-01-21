local ffi = require('ffi')
local band, shr = bit.band, bit.rshift
local _byteOrder, _parseByteOrder, _Union
local _tags, _getTag, _taggedReaders, _unpackMap, _arrayTypeMap
local BlobReader
do
  local _class_0
  local _base_0 = {
    read = function(self)
      local tag, value = self:_readTagged()
      return value
    end,
    number = function(self)
      self._union.u32[0], self._union.u32[1] = self:u32(), self:u32()
      return self._union.f64
    end,
    string = function(self)
      local len, ptr = self:vu32(), self._readPtr
      if self._size <= ptr + len - 1 then
        error("Out of data")
      end
      self._readPtr = ptr + len
      return ffi.string(ffi.cast('uint8_t*', self._data + ptr), len)
    end,
    bool = function(self)
      return self:u8() ~= 0
    end,
    table = function(self, result)
      if result == nil then
        result = { }
      end
      local tag, key = self:_readTagged()
      while tag ~= _tags.stop do
        tag, result[key] = self:_readTagged()
        tag, key = self:_readTagged()
      end
      return result
    end,
    u8 = function(self)
      if self._size <= self._readPtr then
        error("Out of data")
      end
      local u8 = self._data[self._readPtr]
      self._readPtr = self._readPtr + 1
      return u8
    end,
    s8 = function(self)
      self._union.u8[0] = self:u8()
      return self._union.s8[0]
    end,
    u16 = function(self)
      local ptr = self._readPtr
      if self._size <= ptr + 1 then
        error("Out of data")
      end
      self._readPtr = ptr + 2
      return self._orderBytes._16(self, self._data[ptr], self._data[ptr + 1])
    end,
    s16 = function(self)
      self._union.u16[0] = self:u16()
      return self._union.s16[0]
    end,
    u32 = function(self)
      local ptr = self._readPtr
      if self._size <= ptr + 3 then
        error("Out of data")
      end
      self._readPtr = ptr + 4
      return self._orderBytes._32(self, self._data[ptr], self._data[ptr + 1], self._data[ptr + 2], self._data[ptr + 3])
    end,
    s32 = function(self)
      self._union.u32[0] = self:u32()
      return self._union.s32[0]
    end,
    u64 = function(self)
      local ptr = self._readPtr
      if self._size <= ptr + 7 then
        error("Out of data")
      end
      self._readPtr = ptr + 8
      return self._orderBytes._64(self, self._data[ptr], self._data[ptr + 1], self._data[ptr + 2], self._data[ptr + 3], self._data[ptr + 4], self._data[ptr + 5], self._data[ptr + 6], self._data[ptr + 7])
    end,
    s64 = function(self)
      self._union.u64 = self:u64()
      return self._union.s64
    end,
    f32 = function(self)
      self._union.u32[0] = self:u32()
      return self._union.f32[0]
    end,
    f64 = function(self)
      return self:number()
    end,
    vu32 = function(self)
      local result = self:u8()
      if band(result, 0x00000080) == 0 then
        return result
      end
      result = band(result, 0x0000007f) + self:u8() * 2 ^ 7
      if band(result, 0x00004000) == 0 then
        return result
      end
      result = band(result, 0x00003fff) + self:u8() * 2 ^ 14
      if band(result, 0x00200000) == 0 then
        return result
      end
      result = band(result, 0x001fffff) + self:u8() * 2 ^ 21
      if band(result, 0x10000000) == 0 then
        return result
      end
      return band(result, 0x0fffffff) + self:u8() * 2 ^ 28
    end,
    vs32 = function(self)
      local result = self:u8()
      local sign
      sign, result = band(result, 1) == 0 and 1 or -1, shr(result, 1)
      if band(result, 0x00000040) == 0 then
        return result * sign
      end
      result = band(result, 0x0000003f) + self:u8() * 2 ^ 6
      if band(result, 0x00002000) == 0 then
        return result * sign
      end
      result = band(result, 0x00001fff) + self:u8() * 2 ^ 13
      if band(result, 0x00100000) == 0 then
        return result * sign
      end
      result = band(result, 0x000fffff) + self:u8() * 2 ^ 20
      if band(result, 0x08000000) == 0 then
        return result * sign
      end
      return sign * (band(result, 0x07ffffff) + self:u8() * 2 ^ 27)
    end,
    raw = function(self, len)
      local ptr = self._readPtr
      if self._size <= ptr + len - 1 then
        error("Out of data")
      end
      self._readPtr = ptr + len
      return ffi.string(ffi.cast('uint8_t*', self._data + ptr), len)
    end,
    skip = function(self, len)
      if self._size <= self._readPtr + len - 1 then
        error("Out of data")
      end
      self._readPtr = self._readPtr + len
      return self
    end,
    cstring = function(self)
      local ptr, start = self._readPtr, self._readPtr
      while ptr < self._size and self._data[ptr] > 0 do
        ptr = ptr + 1
      end
      if self._size == ptr then
        error("Out of data")
      end
      local len
      self._readPtr, len = ptr + 1, ptr - start
      if len >= 2 ^ 32 then
        error("String too long")
      end
      return ffi.string(ffi.cast('uint8_t*', self._data + start), len)
    end,
    array = function(self, valueType, count, result)
      if result == nil then
        result = { }
      end
      local reader = _arrayTypeMap[valueType]
      if not (reader) then
        error("Invalid array type <" .. tostring(valueType) .. ">")
      end
      local length = count or self:vu32()
      for i = 1, length do
        result[i] = reader(self)
      end
      return result
    end,
    unpack = function(self, format)
      local result, len, lenContext = { }, nil, nil
      local raw
      raw = function()
        local l = tonumber(table.concat(len))
        if not (l) then
          error("Invalid string length specification: " .. tostring(table.concat(len)))
        end
        if l >= 2 ^ 32 then
          error("Maximum string length exceeded")
        end
        table.insert(result, self:raw(l))
        len = nil
      end
      local skip
      skip = function()
        self:skip(tonumber(table.concat(len)) or 1)
        len = nil
      end
      format:gsub('.', function(c)
        if len then
          if tonumber(c) then
            table.insert(len, c)
          else
            lenContext()
          end
        end
        if not (len) then
          local parser = _unpackMap[c]
          if not (parser) then
            error("Invalid data type specifier: " .. tostring(c))
          end
          local _exp_0 = c
          if 'c' == _exp_0 then
            len, lenContext = { }, raw
          elseif 'x' == _exp_0 then
            len, lenContext = { }, skip
          else
            local parsed = parser(self)
            if parsed ~= nil then
              return table.insert(result, parsed)
            end
          end
        end
      end)
      if len then
        lenContext()
      end
      return unpack(result)
    end,
    size = function(self)
      return self._size
    end,
    reset = function(self, data, size)
      if type(data) == 'string' then
        self:_allocate(#data)
        ffi.copy(self._data, data, #data)
      elseif type(data) == 'cdata' then
        self._size = size or ffi.sizeof(data)
        self._data = data
      elseif data == nil then
        self._size = 0
        self._data = nil
      else
        error("Invalid data type <" .. tostring(type(data)) .. ">")
      end
      return self:seek(0)
    end,
    seek = function(self, pos)
      if pos < 0 then
        pos = self._size + pos
      end
      if pos > self._size then
        error("Out of data")
      end
      if pos < 0 then
        error("Invalid read position")
      end
      self._readPtr = pos
      return self
    end,
    position = function(self)
      return self._readPtr
    end,
    setByteOrder = function(self, byteOrder)
      self._orderBytes = _byteOrder[_parseByteOrder(byteOrder)]
      return self
    end,
    _allocate = function(self, size)
      local data
      if size > 0 then
        data = ffi.new('uint8_t[?]', size)
      end
      self._data, self._size = data, size
    end,
    _readTagged = function(self)
      local tag = self:u8()
      return tag, tag ~= _tags.stop and _taggedReaders[tag](self)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, data, sizeOrByteOrder, size)
      self._union = _Union()
      local byteOrder = type(sizeOrByteOrder) == 'string' and sizeOrByteOrder or nil
      size = type(sizeOrByteOrder) == 'number' and sizeOrByteOrder or size
      self:reset(data, size)
      return self:setByteOrder(byteOrder)
    end,
    __base = _base_0,
    __name = "BlobReader"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  BlobReader = _class_0
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
  if value == true or value == false then
    return _tags[value]
  end
  return _tags[type(value)]
end
_byteOrder = {
  le = {
    _16 = function(self, b1, b2)
      self._union.u8[0], self._union.u8[1] = b1, b2
      return self._union.u16[0]
    end,
    _32 = function(self, b1, b2, b3, b4)
      self._union.u8[0], self._union.u8[1], self._union.u8[2], self._union.u8[3] = b1, b2, b3, b4
      return self._union.u32[0]
    end,
    _64 = function(self, b1, b2, b3, b4, b5, b6, b7, b8)
      self._union.u8[0], self._union.u8[1], self._union.u8[2], self._union.u8[3] = b1, b2, b3, b4
      self._union.u8[4], self._union.u8[5], self._union.u8[6], self._union.u8[7] = b5, b6, b7, b8
      return self._union.u64
    end
  },
  be = {
    _16 = function(self, b1, b2)
      self._union.u8[0], self._union.u8[1] = b2, b1
      return self._union.u16[0]
    end,
    _32 = function(self, b1, b2, b3, b4)
      self._union.u8[0], self._union.u8[1], self._union.u8[2], self._union.u8[3] = b4, b3, b2, b1
      return self._union.u32[0]
    end,
    _64 = function(self, b1, b2, b3, b4, b5, b6, b7, b8)
      self._union.u8[0], self._union.u8[1], self._union.u8[2], self._union.u8[3] = b8, b7, b6, b5
      self._union.u8[4], self._union.u8[5], self._union.u8[6], self._union.u8[7] = b4, b3, b2, b1
      return self._union.u64
    end
  }
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
  _taggedReaders = {
    BlobReader.number,
    BlobReader.string,
    BlobReader.table,
    function(self)
      return true
    end,
    function(self)
      return false
    end,
    function(self)
      return 0
    end,
    BlobReader.vs32,
    BlobReader.vu32,
    function(self)
      self._union.s32[0], self._union.s32[1] = self:vs32(), self:vs32()
      return self._union.s64
    end,
    function(self)
      self._union.u32[0], self._union.u32[1] = self:vu32(), self:vu32()
      return self._union.u64
    end
  }
  _arrayTypeMap = {
    s8 = BlobReader.s8,
    u8 = BlobReader.u8,
    s16 = BlobReader.s16,
    u16 = BlobReader.u16,
    s32 = BlobReader.s32,
    u32 = BlobReader.u32,
    s64 = BlobReader.s64,
    u64 = BlobReader.u64,
    vs32 = BlobReader.vs32,
    vu32 = BlobReader.vu32,
    f32 = BlobReader.f32,
    f64 = BlobReader.f64,
    number = BlobReader.number,
    string = BlobReader.string,
    cstring = BlobReader.cstring,
    bool = BlobReader.bool,
    table = BlobReader.table
  }
  _unpackMap = {
    b = BlobReader.s8,
    B = BlobReader.u8,
    h = BlobReader.s16,
    H = BlobReader.u16,
    l = BlobReader.s32,
    L = BlobReader.u32,
    v = BlobReader.vs32,
    V = BlobReader.vu32,
    q = BlobReader.s64,
    Q = BlobReader.u64,
    f = BlobReader.f32,
    d = BlobReader.number,
    n = BlobReader.number,
    c = BlobReader.raw,
    s = BlobReader.string,
    z = BlobReader.cstring,
    t = BlobReader.table,
    y = BlobReader.bool,
    x = function(self)
      return nil, self:skip(1)
    end,
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
return BlobReader
