
set(CPM_DOWNLOAD_VERSION "0.40.8" CACHE STRING "CPM version to download")
set(CPM_HASH_SUM "78ba32abdf798bc616bab7c73aac32a17bbd7b06ad9e26a6add69de8f3ae4791" CACHE STRING "CPM download hash")
set(CPM_REPOSITORY_URL "https://github.com/cpm-cmake/CPM.cmake" CACHE STRING "CPM repository URL")

include(downloader/CPMDownloader)
