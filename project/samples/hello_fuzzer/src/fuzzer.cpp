//#include <cstdint>
//#include <cstddef>
//#include <span>
//
//// This is the fuzz target function that will be called by the fuzzer
//extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size)
//{
//    if (size == 0)
//        return 0; // Ignore empty inputs
//
//    // Convert the raw bytes to input your function expects
//    // For example, if your function takes a std::vector:
//    std::span<const uint8_t> input(data, data + size);
//
//    // Call your function to test
//    // your_function_to_test(input);
//
//    // Or if your function takes raw pointers:
//    // your_function_to_test(data, size);
//
//    return 0; // Non-zero return values are reserved for future use
//}

// CMakeProject1.cpp : Defines the entry point for the application

#include <stdio.h>

int x[100];

int main()
{
    printf("Hello!\n");
    x[100] = 5; // Boom!
    return 0;
}