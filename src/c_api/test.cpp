#include "Halcyon.h"
#include <iostream>
#include <wInDOWs.h>

int main(int argc, char** argv)
{    // Set console code page to UTF-8 so console known how to interpret string data
    SetConsoleOutputCP(CP_UTF8);

    // Enable buffering to prevent VS from chopping up UTF-8 byte sequences
    setvbuf(stdout, nullptr, _IOFBF, 1000);
    std::cout << "hello world" << std::endl;

    HalcStory story;

    HalcStory_Parse(
        "[hello]\n"
        "wanker: fuck you\n"
        "personA: fuck you too\n"
        "    > I hate you: \n"
        "        wanker: fuck you mate",
        &story
    );

    HalcStory_CreateInteractorFromStart(&story);

    HalcStory_Destroy(&story);
}
