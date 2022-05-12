#include "Halcyon.h"
#include <iostream>
#include <wInDOWs.h>

int main(int argc, char** argv)
{    // Set console code page to UTF-8 so console known how to interpret string data
    SetConsoleOutputCP(CP_UTF8);

    // Enable buffering to prevent VS from chopping up UTF-8 byte sequences
    setvbuf(stdout, nullptr, _IOFBF, 1000);
    std::cout << "hello world" << std::endl;

    halc_do_parse(
        "[hello]\n"
        "wanker: fuck you\n"
        "personA: fuck you too\n"
        "    > I hate you: \n"
        "        wanker: fuck you mate"
    );

    thick_c_handle_t x;
    
    auto i = halc_test_struct(&x);

    std::cout << "😍😍😍😍😍😍😍" << i << " " << x.buf << std::endl;
}
