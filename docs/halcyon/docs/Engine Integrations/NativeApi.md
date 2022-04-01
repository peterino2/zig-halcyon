# Native C API

- Native C api that calls into the zig based runtime

use this if you want

- Direct control of memory management 
- Direct control of compute
- Integration into any other engine that is not Unity or Unreal engine

```{C}

// All cars
struct hstring_t{
    char* s;
    size_t len;
};

struct const_hstring_t{
    const char* s;
    size_t len;
};

const_halc_chars_t HalcCharsConvertToConst(halc_chars_t c) { return struct const_halc_chars_t {c.start, c.len }; }

```