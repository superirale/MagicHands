#include "physics/NoiseGenerator.h"
#include <cmath>
#include <cstdlib>
#include <ctime>

// Static initialization
int NoiseGenerator::p[512];
bool NoiseGenerator::initialized = false;

void NoiseGenerator::initPermutation() {
    if (initialized) return;
    
    // Standard Perlin permutation table
    static int permutation[] = { 
        151,160,137,91,90,15,131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,
        8,99,37,240,21,10,23,190,6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,
        35,11,32,57,177,33,88,237,149,56,87,174,20,125,136,171,168,68,175,74,165,71,
        134,139,48,27,166,77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,
        55,46,245,40,244,102,143,54,65,25,63,161,1,216,80,73,209,76,132,187,208,89,
        18,169,200,196,135,130,116,188,159,86,164,100,109,198,173,186,3,64,52,217,226,
        250,124,123,5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,
        189,28,42,223,183,170,213,119,248,152,2,44,154,163,70,221,153,101,155,167,43,
        172,9,129,22,39,253,19,98,108,110,79,113,224,232,178,185,112,104,218,246,97,
        228,251,34,242,193,238,210,144,12,191,179,162,241,81,51,145,235,249,14,239,
        107,49,192,214,31,181,199,106,157,184,84,204,176,115,121,50,45,127,4,150,254,
        138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
    };
    
    // Duplicate permutation table
    for (int i = 0; i < 256; i++) {
        p[i] = permutation[i];
        p[256 + i] = permutation[i];
    }
    
    initialized = true;
}

float NoiseGenerator::fade(float t) {
    // 6t^5 - 15t^4 + 10t^3
    return t * t * t * (t * (t * 6 - 15) + 10);
}

float NoiseGenerator::lerp(float t, float a, float b) {
    return a + t * (b - a);
}

float NoiseGenerator::grad(int hash, float x, float y) {
    // Convert hash to one of 8 gradient directions
    int h = hash & 7;
    float u = h < 4 ? x : y;
    float v = h < 4 ? y : x;
    return ((h & 1) ? -u : u) + ((h & 2) ? -2.0f * v : 2.0f * v);
}

float NoiseGenerator::perlin2D(float x, float y, float scale) {
    initPermutation();
    
    // Apply scale
    x *= scale;
    y *= scale;
    
    // Find unit grid cell containing point
    int X = (int)std::floor(x) & 255;
    int Y = (int)std::floor(y) & 255;
    
    // Get relative position within cell
    x -= std::floor(x);
    y -= std::floor(y);
    
    // Compute fade curves
    float u = fade(x);
    float v = fade(y);
    
    // Hash coordinates of corners
    int aa = p[p[X] + Y];
    int ab = p[p[X] + Y + 1];
    int ba = p[p[X + 1] + Y];
    int bb = p[p[X + 1] + Y + 1];
    
    // Blend results from corners
    float x1 = lerp(u, grad(aa, x, y), grad(ba, x - 1, y));
    float x2 = lerp(u, grad(ab, x, y - 1), grad(bb, x - 1, y - 1));
    
    return lerp(v, x1, x2);
}

float NoiseGenerator::octaveNoise(float x, float y, int octaves, float persistence, float scale) {
    float total = 0.0f;
    float frequency = scale;
    float amplitude = 1.0f;
    float maxValue = 0.0f;
    
    for (int i = 0; i < octaves; i++) {
        total += perlin2D(x, y, frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0f;
    }
    
    return total / maxValue;
}

// Lua bindings
int Lua_GenerateNoise(lua_State* L) {
    float x = (float)luaL_checknumber(L, 1);
    float y = (float)luaL_checknumber(L, 2);
    float scale = (float)luaL_optnumber(L, 3, 0.1);
    
    float noise = NoiseGenerator::perlin2D(x, y, scale);
    lua_pushnumber(L, noise);
    return 1;
}

int Lua_OctaveNoise(lua_State* L) {
    float x = (float)luaL_checknumber(L, 1);
    float y = (float)luaL_checknumber(L, 2);
    int octaves = (int)luaL_optinteger(L, 3, 4);
    float persistence = (float)luaL_optnumber(L, 4, 0.5);
    float scale = (float)luaL_optnumber(L, 5, 0.1);
    
    float noise = NoiseGenerator::octaveNoise(x, y, octaves, persistence, scale);
    lua_pushnumber(L, noise);
    return 1;
}

void NoiseGenerator::RegisterLua(lua_State* L) {
    lua_newtable(L);
    lua_pushcfunction(L, Lua_GenerateNoise);
    lua_setfield(L, -2, "generate");
    lua_pushcfunction(L, Lua_OctaveNoise);
    lua_setfield(L, -2, "octave");
    lua_setglobal(L, "noise");
}
