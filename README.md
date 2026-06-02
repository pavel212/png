# PNG files without compression
Single header library to write raw data into .png files without compression.
Just to store raw data of 1,2,3,4,6,8 bytes per sample in a png "container".
Or so small images, that compression does not make much sense[^1].
For creating actual png images use some normal png library like stb_image_write[^2] / lodepng[^3] / libpng[^4] / ...

# Usage
```C
#define WRITE_PNG_IMPLEMENTATION
#include "write_png.h"

void main(){
  uint8_t data[2*2*3]={0xFF,0x00,0x00,  0x00,0xFF,0x00,    //2x2 image: |RG|
                       0x00,0x00,0xFF,  0xFF,0xFF,0xFF};   //           |BW|
  write_png("2x2.png", data, 2, 2, PNG_RGB, (char*[]){"Title\0title", "Comment\0comment", 0});
}
```

```Lua
png = require ("png")
local data = "\xFF\x00\x00".."\x00\xFF\x00".."\x00\x00\xFF".."\xFF\xFF\xFF"
png.write("2x2.png", data, 2, 2, png.RGB, {"Title\x00title", "Comment\x00comment"});
```

# write_png()
```C
int write_png(const char *fn, const void *data, uint32_t width, uint32_t height, uint32_t type, const char **text);
```

- uint32_t type: 0 | [PNG_RGB] | [PNG_ALPHA] | [PNG_16BIT]

|type|bpp|
|---|---|
|PNG_GRAY==0|8|
|PNG_GRAYALPHA==PNG_ALPHA|16|
|PNG_GRAY16==PNG_16BIT|16|
|PNG_GRAYALPHA16|32|
|PNG_RGB|24|
|PNG_RGBA|32|
|PNG_RGB16|48|
|PNG_RGBA16|64|

- const char **text: 0 terminated array of '\0' separated pairs of "keyword\0text", or 0 for no tEXt section

- return value

|||
|---|---|
|0 |OK| 
|-1|fopen failed|
|-2|fwrite failed|

# ToDo
[ ] multiframe APNG

# Links
[^1]: https://iquilezles.org/articles/minipng64
[^2]: https://github.com/nothings/stb
[^3]: https://lodev.org/lodepng
[^4]: https://www.libpng.org/pub/png/libpng.html
