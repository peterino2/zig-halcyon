#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef WIN32
#define EXPORT_API __declspec(dllexport)
#else 
#define EXPORT_API 
#endif

typedef struct halc_nodes_t halc_nodes_t;

typedef struct HalcString {
    size_t len;
    char* utf8;
} HalcString;

// fat pointer with info
typedef struct HalcStory {
    size_t num_nodes;
    halc_nodes_t* nodes;
} HalcStory;

// returns 0 on success
EXPORT_API int HalcStory_Parse(const char* cstr, HalcStory* story);

EXPORT_API void HalcStory_Destroy(HalcStory* story);

// fat pointer with info
typedef struct HalcInteractor {
    uint32_t id;
} HalcInteractor;

// returns 0 on success
EXPORT_API int HalcStory_CreateInteractorFromStart(
    HalcStory*story,
    HalcInteractor* interactor,
    );

// retursn 0 on success
EXPORT_API int HalcStory_CreateInteractor(
    HalcStory*story,
    HalcInteractor* interactor,
    const char* start_label);

EXPORT_API void HalcInteractor_GetStoryText(
    HalcStory* story,
    const HalcInteractor* interactor,
    HalcString* ostr);
    
EXPORT_API void HalcInteractor_GetSpeaker(
    HalcStory* story,
    const HalcInteractor* interactor,
    HalcString* ostr);  

// returns the ID of the next node we traveled to. returns -1 if we reached the end of the story.
EXPORT_API int HalcInteractor_Next(
    HalcStory* story,
    HalcInteractor* interactor);
    
typedef struct HalcChoicesList {
    size_t len;
    uint32_t* ids;
    const char** strings;
} HalcChoicesList;

EXPORT_API void HalcChoicesList_Destroy(
    HalcChoicesList* choices);

// returns the number of choices
EXPORT_API int HalcInteractor_GetChoices(
    HalcStory* story,
    const HalcInteractor* interactor,
    HalcChoicesList* list);

// returns the ID of the next node we traveled to. returns -1 if we reached the end of the story.
EXPORT_API int HalcInteractor_SelectChoice(
    HalcStory* story,
    HalcInteractor* interactor,
    size_t choice);


#ifdef __cplusplus
}
#endif


