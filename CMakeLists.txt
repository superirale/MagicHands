cmake_minimum_required(VERSION 3.20)
project(MagicHand VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# --- SDL3 ---
FetchContent_Declare(
    SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG preview-3.3.2 # Use a recent tag or commit
)
FetchContent_MakeAvailable(SDL3)

# --- Lua 5.4 ---
# Using a FetchContent-compatible Lua wrapper
FetchContent_Declare(
    lua
    GIT_REPOSITORY https://github.com/walterschell/Lua.git
    GIT_TAG v5.4.6
)
set(LUA_BUILD_COMPILER OFF CACHE BOOL "" FORCE)
set(LUA_BUILD_INTERPRETER OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(lua)

# --- LuaSocket ---
FetchContent_Declare(
    luasocket
    GIT_REPOSITORY https://github.com/lunarmodules/luasocket.git
    GIT_TAG master
)
FetchContent_MakeAvailable(luasocket)

# Manually define LuaSocket targets since upstream lacks root CMakeLists.txt
set(LUASOCKET_SRC_DIR ${luasocket_SOURCE_DIR}/src)

# Core sources (common)
set(LUASOCKET_CORE_SRCS
    ${LUASOCKET_SRC_DIR}/luasocket.c
    ${LUASOCKET_SRC_DIR}/timeout.c
    ${LUASOCKET_SRC_DIR}/buffer.c
    ${LUASOCKET_SRC_DIR}/io.c
    ${LUASOCKET_SRC_DIR}/auxiliar.c
    ${LUASOCKET_SRC_DIR}/options.c
    ${LUASOCKET_SRC_DIR}/inet.c
    ${LUASOCKET_SRC_DIR}/tcp.c
    ${LUASOCKET_SRC_DIR}/udp.c
    ${LUASOCKET_SRC_DIR}/except.c
    ${LUASOCKET_SRC_DIR}/select.c
)

if (WIN32)
    list(APPEND LUASOCKET_CORE_SRCS ${LUASOCKET_SRC_DIR}/wsocket.c)
else()
    list(APPEND LUASOCKET_CORE_SRCS ${LUASOCKET_SRC_DIR}/usocket.c)
endif()

add_library(luasocket_core STATIC ${LUASOCKET_CORE_SRCS})
target_include_directories(luasocket_core PRIVATE ${LUASOCKET_SRC_DIR} ${lua_SOURCE_DIR}/lua-5.4.6/include)
target_compile_definitions(luasocket_core PRIVATE LUASOCKET_DEBUG)
if (NOT WIN32)
    target_compile_definitions(luasocket_core PRIVATE UNIX_HAS_SUN_LEN)
endif()

# MIME sources
set(LUASOCKET_MIME_SRCS
    ${LUASOCKET_SRC_DIR}/mime.c
    ${LUASOCKET_SRC_DIR}/compat.c
)
add_library(luasocket_mime STATIC ${LUASOCKET_MIME_SRCS})
target_include_directories(luasocket_mime PRIVATE ${LUASOCKET_SRC_DIR} ${lua_SOURCE_DIR}/lua-5.4.6/include)

# --- Box2D ---
FetchContent_Declare(
    box2d
    GIT_REPOSITORY https://github.com/erincatto/box2d.git
    GIT_TAG v3.0.0
)
FetchContent_MakeAvailable(box2d)

# --- stb ---
FetchContent_Declare(
    stb
    GIT_REPOSITORY https://github.com/nothings/stb.git
    GIT_TAG master
)
FetchContent_MakeAvailable(stb)

# --- JSON ---
FetchContent_Declare(
    json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.3
)
FetchContent_MakeAvailable(json)

# --- Orpheus Audio ---
FetchContent_Declare(
    orpheus
    GIT_REPOSITORY https://github.com/superirale/Orpheus.git
    GIT_TAG master
)
# SoLoud uses C++17 filesystem which needs explicit link on some platforms,
# but Orpheus CMake handles most of it.
FetchContent_MakeAvailable(orpheus)

# --- Tracy Profiler (Optional) ---
option(MagicHand_ENABLE_TRACY "Enable Tracy profiler integration" OFF)

if(MagicHand_ENABLE_TRACY)
    FetchContent_Declare(
        tracy
        GIT_REPOSITORY https://github.com/wolfpld/tracy.git
        GIT_TAG v0.11.1
        GIT_SHALLOW TRUE
    )
    FetchContent_MakeAvailable(tracy)
endif()

# --- Main Executable ---
add_executable(MagicHand 
    src/core/main.cpp 
    src/core/WindowManager.cpp
    src/graphics/SpriteRenderer.cpp
    src/physics/PhysicsSystem.cpp
    src/input/InputSystem.cpp
    src/audio/AudioSystem.cpp
    src/graphics/FontRenderer.cpp
    src/core/JsonUtils.cpp
    src/ui/UISystem.cpp
    src/ui/UILayout.cpp
    src/graphics/Animation.cpp
    src/physics/NoiseGenerator.cpp
    src/graphics/ParticleSystem.cpp
    src/events/EventSystem.cpp
    src/core/Logger.cpp
    src/core/Engine.cpp
    src/scripting/LuaBindings.cpp
    src/scripting/WindowManagerBindings.cpp
    src/scripting/ProfilerBindings.cpp
    src/graphics/DebugDraw.cpp
    src/asset/AssetManager.cpp
    src/asset/AssetConfig.cpp
    src/core/Base64.cpp
    # Tilemap system
    src/tilemap/TileSet.cpp
    src/tilemap/TileLayer.cpp
    src/tilemap/ObjectLayer.cpp
    src/tilemap/TileMap.cpp
    src/scripting/TileMapBindings.cpp
    # Pathfinding system
    src/pathfinding/Pathfinder.cpp
    src/scripting/PathfindingBindings.cpp
    # Spatial partitioning system
    src/core/SpatialIndex.cpp
    src/scripting/SpatialBindings.cpp
    # Card system (gameplay)
    src/gameplay/card/Card.cpp
    src/gameplay/card/Deck.cpp
    src/scripting/CardBindings.cpp
    # Cribbage scoring (gameplay)
    src/gameplay/cribbage/HandEvaluator.cpp
    src/gameplay/cribbage/ScoringEngine.cpp
    src/gameplay/cribbage/RuleType.cpp
    src/gameplay/cribbage/effects/BlazeEffect.cpp
    src/gameplay/cribbage/effects/MirrorEffect.cpp
    src/gameplay/cribbage/effects/InversionEffect.cpp
    src/gameplay/cribbage/effects/WildfireEffect.cpp
    src/gameplay/cribbage/effects/EffectFactory.cpp
    src/scripting/CribbageBindings.cpp
    # Joker system (gameplay)
    src/gameplay/joker/Joker.cpp
    src/gameplay/joker/JokerEffectSystem.cpp
    src/scripting/JokerBindings.cpp
    # Blind & Boss system (gameplay)
    src/gameplay/blind/Blind.cpp
    src/gameplay/boss/Boss.cpp
    src/scripting/BlindBindings.cpp
)

# Link libraries
# Note: linking Orpheus::orpheus (FetchContent alias)
target_link_libraries(MagicHand
    PRIVATE
    SDL3::SDL3
    lua_static
    box2d
    nlohmann_json::nlohmann_json
    Orpheus::orpheus
    luasocket_core
    luasocket_mime
)
target_include_directories(MagicHand PRIVATE src ${stb_SOURCE_DIR} ${lua_SOURCE_DIR}/lua-5.4.6/include)
target_precompile_headers(MagicHand PRIVATE src/core/pch.h)

# Tracy profiler (conditional)
if(MagicHand_ENABLE_TRACY)
    target_link_libraries(MagicHand PRIVATE TracyClient)
    target_compile_definitions(MagicHand PRIVATE TRACY_ENABLE)
endif()

find_package(ZLIB REQUIRED)
target_link_libraries(MagicHand PRIVATE ZLIB::ZLIB)

# Copy content directory to build directory
add_custom_command(TARGET MagicHand POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/content ${CMAKE_BINARY_DIR}/content)

# --- Catch2 Testing ---
FetchContent_Declare(
    Catch2
    GIT_REPOSITORY https://github.com/catchorg/Catch2.git
    GIT_TAG v3.5.2
)
FetchContent_MakeAvailable(Catch2)

# Test executable
enable_testing()

# Collect test source files
file(GLOB_RECURSE TEST_SOURCES tests/*.cpp)

if(TEST_SOURCES)
    add_executable(magic_hands_tests ${TEST_SOURCES} src/core/Base64.cpp)
    target_link_libraries(magic_hands_tests PRIVATE Catch2::Catch2WithMain nlohmann_json::nlohmann_json)
    target_include_directories(magic_hands_tests PRIVATE src ${stb_SOURCE_DIR})
    
    # Register tests with CTest
    list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
    include(CTest)
    include(Catch)
    catch_discover_tests(magic_hands_tests)
endif()
