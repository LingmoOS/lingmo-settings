find_package(Qt6 REQUIRED COMPONENTS Core Test)

# Pure heuristics of the AI page: model tags and the whisper model for this computer
add_executable(tst_aiheuristics tst_aiheuristics.cpp ${CMAKE_SOURCE_DIR}/src/aiheuristics.cpp)
target_include_directories(tst_aiheuristics PRIVATE ${CMAKE_SOURCE_DIR}/src)
target_link_libraries(tst_aiheuristics PRIVATE Qt6::Core Qt6::Test)
add_test(NAME tst_aiheuristics COMMAND tst_aiheuristics)
