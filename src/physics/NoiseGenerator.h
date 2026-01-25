#pragma once
#include <lua.hpp>

// Perlin noise generator for procedural world generation
class NoiseGenerator {
public:
    // 2D Perlin noise function
    // Returns value in range [-1, 1]
    static float perlin2D(float x, float y, float scale = 1.0f);
    
    // Octave-based noise (layered noise for more natural terrain)
    static float octaveNoise(float x, float y, int octaves, float persistence, float scale);
    
    // Register Lua bindings
    static void RegisterLua(lua_State* L);
    
private:
    // Perlin noise helpers
    static float fade(float t);
    static float lerp(float t, float a, float b);
    static float grad(int hash, float x, float y);
    
    // Permutation table for noise generation
    static int p[512];
    static void initPermutation();
    static bool initialized;
};

// Lua bindings
int Lua_GenerateNoise(lua_State* L);
int Lua_OctaveNoise(lua_State* L);
