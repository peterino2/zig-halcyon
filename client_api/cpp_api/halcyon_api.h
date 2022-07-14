#pragma once

#include "Halcyon.h"

class HalcyonInteractor;
class HalcyonString;
class HalcyonChoicesList;

class HalcyonStory{

public:

    HalcStory _story;

    void ParseFromString(const char* cstring);
};


class HalcyonString{

public:
    HalcString _string;

};
