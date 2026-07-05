#include <cstdlib>

// The extern "C" is required for DPI to find it
extern "C" const char* sv_getenv(const char* env_name) {
    // std::getenv returns char*, which safely converts to const char*
    char* result = std::getenv(env_name);
    if (result == nullptr)
        return ".";
    return result;
}
