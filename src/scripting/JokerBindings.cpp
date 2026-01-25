#include "gameplay/card/Card.h"
#include "gameplay/cribbage/HandEvaluator.h"
#include "gameplay/joker/Joker.h"
#include "gameplay/joker/JokerEffectSystem.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

using namespace gameplay;

// ===== Joker Bindings =====

static int Lua_JokerLoad(lua_State *L) {
  const char *filePath = luaL_checkstring(L, 1);

  try {
    Joker joker = Joker::FromJSON(filePath);

    // Return joker as Lua table
    lua_newtable(L);

    lua_pushstring(L, joker.id.c_str());
    lua_setfield(L, -2, "id");

    lua_pushstring(L, joker.name.c_str());
    lua_setfield(L, -2, "name");

    lua_pushstring(L, joker.description.c_str());
    lua_setfield(L, -2, "description");

    lua_pushstring(L, joker.rarity.c_str());
    lua_setfield(L, -2, "rarity");

    lua_pushboolean(L, joker.ignoresCaps);
    lua_setfield(L, -2, "ignoresCaps");

    return 1;
  } catch (const std::exception &e) {
    lua_pushnil(L);
    lua_pushstring(L, e.what());
    return 2;
  }
}

static int Lua_JokerApplyEffects(lua_State *L) {
  // Args: jokerPaths (table), hand (table of 5 cards), trigger (string)
  luaL_checktype(L, 1, LUA_TTABLE);
  luaL_checktype(L, 2, LUA_TTABLE);
  const char *trigger = luaL_checkstring(L, 3);

  // Load all jokers from paths
  std::vector<Joker> jokers;
  int jokerCount = lua_rawlen(L, 1);
  for (int i = 1; i <= jokerCount; ++i) {
    lua_rawgeti(L, 1, i);
    const char *path = lua_tostring(L, -1);
    lua_pop(L, 1);

    try {
      jokers.push_back(Joker::FromJSON(path));
    } catch (...) {
      // Skip invalid jokers
    }
  }

  // Extract cards from hand
  std::vector<Card> hand;
  for (int i = 1; i <= 4; ++i) {
    lua_rawgeti(L, 2, i);
    Card *card = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
    hand.push_back(*card);
    lua_pop(L, 1);
  }

  // Extract cut card
  lua_rawgeti(L, 2, 5);
  Card *cutCard = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
  lua_pop(L, 1);

  // Evaluate hand
  HandEvaluator::HandResult handResult =
      HandEvaluator::Evaluate(hand, *cutCard);

  // Apply joker effects
  JokerEffectSystem::EffectResult effects =
      JokerEffectSystem::ApplyJokers(jokers, handResult, trigger);

  // Return effect result as table
  lua_newtable(L);

  lua_pushinteger(L, effects.addedChips);
  lua_setfield(L, -2, "addedChips");

  lua_pushnumber(L, effects.addedTempMult);
  lua_setfield(L, -2, "addedTempMult");

  lua_pushnumber(L, effects.addedPermMult);
  lua_setfield(L, -2, "addedPermMult");

  lua_pushboolean(L, effects.ignoresCaps);
  lua_setfield(L, -2, "ignoresCaps");

  return 1;
}

void RegisterJokerBindings(lua_State *L) {
  // Register joker global table
  lua_newtable(L);

  lua_pushcfunction(L, Lua_JokerLoad);
  lua_setfield(L, -2, "load");

  lua_pushcfunction(L, Lua_JokerApplyEffects);
  lua_setfield(L, -2, "applyEffects");

  lua_setglobal(L, "joker");
}
