include(TargetSanitizers)

# add fuzzer target
add_executable(HelloFuzzer "src/fuzzer.cpp")

targets_enable_sanitizers(
	TARGETS HelloFuzzer
    SCOPE PRIVATE
	ENABLE_SANITIZER_ADDRESS ON
	ENABLE_SANITIZER_FUZZER ON
	HAVE_SANITIZER HAVE_SANITIZER
)

if (${HAVE_SANITIZER})
	# install the component
	install_component(
		HelloFuzzer
	)
else()
	message(STATUS "Fuzzer not supported")
endif()