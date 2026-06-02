local crc_table = {};

for i=0,255 do 
  local c = i
  for j=1,8 do c = (0xedb88320*(c&1))~(c>>1); end
  crc_table[i] = c
end

local function crc32(crc, adler, data)
  local a,b = adler & 0xFFFF, (adler >> 16) & 0xFFFF
  for i = 1, #data do
    local v = data:byte(i)
    a = (a + v) % 65521;
    b = (b + a) % 65521;
    crc = crc_table[(crc ~ v)&0xFF] ~ (crc >> 8); 
  end
  return crc, (b << 16) | a;
end

local png = {GRAY = 0, RGB = 1, ALPHA = 2, BIT16 = 4}

png.GRAYALPHA = png.GRAY | png.ALPHA
png.GRAY16 = png.GRAY | png.BIT16
png.GRAYALPHA16 = png.GRAYALPHA | png.BIT16
png.RGBA = png.RGB | png.ALPHA
png.RGB16 = png.RGB | png.BIT16
png.RGBA16 = png.RGBA | png.BIT16

png.write = function (fn, data, width, height, colordepth, text)
  local bpp        = ((colordepth & png.BIT16) ~=0) and 16 or 8
  local rgb        = ((colordepth & png.RGB) ~=0)   and 1  or 0 
  local alpha      = ((colordepth & png.ALPHA) ~=0) and 1  or 0
  local row_bytes  = width * (1+2*rgb+alpha) * bpp >> 3
  local data_bytes = (row_bytes + 1) * height
  local num_blocks = math.floor((data_bytes + 65534) / 65535)

  local file = io.open(fn, "wb");
  if not file then return end

  local ihdr = "IHDR"..(">I4I4BB"):pack(width,height,bpp,2*rgb+4*alpha).."\x00\x00\x00"
  file:write(
    "\x89PNG\x0D\x0A\x1A\x0A",
    "\x00\x00\x00\x0d", ihdr, (">I4"):pack(crc32(0xFFFFFFFF,0,ihdr)~0xFFFFFFFF),
    (">I4"):pack(data_bytes + 2 + 5 * num_blocks + 4), "IDAT\x78\x01"
  )

  local crc, adler, lastblock, x, y, pos = 0x13E5812D, 1, 0, 0, 0, 0
  local num = data_bytes
 
  while (num > 0) do
    if (pos + num > 65535) then num = 65535 - pos else lastblock = 1 end
    if (pos == 0) then 
      local h = ("<BI2I2"):pack(lastblock, num&0xFFFF, (~num)&0xFFFF)
      file:write(h)
      crc = crc32(crc, 0, h)
    end
    if (x   + num > row_bytes) then num = row_bytes - x end
    if (x   == 0) then
      file:write("\x00")
      crc, adler = crc32(crc, adler, "\x00")
      pos = pos + 1;
      num = num - 1;
    end
    local p = data:sub(x+y*row_bytes+1, x+y*row_bytes+num)
    file:write(p)
    crc, adler = crc32(crc, adler, p)
    pos = pos + num;
    if pos >= 65535 then pos = 0 end
    x = x + num
    if x >= row_bytes then x = 0; y = y+1 end
    num = data_bytes - y*(row_bytes+1) - x
  end
  file:write((">I4I4"):pack(adler, crc32(crc,0,(">I4"):pack(adler))~0xFFFFFFFF))

  for i,v in ipairs(text) do file:write((">I4"):pack(#v), "tEXt", v, (">I4"):pack(crc32(0x69BD3A7A, 0, v)~0xFFFFFFFF)) end

  file:write("\x00\x00\x00\x00IEND\xAE\x42\x60\x82");
  file:close(f);
end

return png