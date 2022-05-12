#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#ifdef WIN32
#define EXPORT_API __declspec(dllexport)
#else 
#define EXPORT_API 
#endif

typedef struct halc_system_handle_t halc_system_handle_t;

typedef struct thick_c_handle_t 
{
    int handle_id;
    char buf[5];
} thick_c_handle_t;

EXPORT_API halc_system_handle_t* halc_do_parse(const char*);

EXPORT_API int halc_test_struct(thick_c_handle_t*);

#ifdef __cplusplus
}
#endif


