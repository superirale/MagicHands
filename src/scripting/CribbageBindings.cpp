#include "gameplay/card/Card.h"
#include "gameplay/card/Deck.h"
#include "gameplay/cribbage/HandEvaluator.h"
#include "gameplay/cribbage/ScoringEngine.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

using namespace gameplay;

// ===== Cribbage Bindings =====

static int Lua_CribbageEvaluate(lua_State *L) {
  // Expect table of 4 cards (hand) and 1 card (cut)
  luaL_checktype(L, 1, LUA_TTABLE);

  // Extract hand cards
  std::vector<Card> hand;
  for (int i = 1; i <= 4; ++i) {
    lua_rawgeti(L, 1, i);
    Card *card = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
    hand.push_back(*card);
    lua_pop(L, 1);
  }

  // Extract cut card (5th card)
  lua_rawgeti(L, 1, 5);
  Card *cutCard = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
  lua_pop(L, 1);

  // Evaluate hand
  HandEvaluator::HandResult result = HandEvaluator::Evaluate(hand, *cutCard);

  // Return result as Lua table
  lua_newtable(L);

  // Fifteens
  lua_newtable(L);
  for (size_t i = 0; i < result.fifteens.size(); ++i) {
    lua_newtable(L);
    for (size_t j = 0; j < result.fifteens[i].size(); ++j) {
      lua_pushinteger(L, result.fifteens[i][j] + 1); // Lua is 1-indexed
      lua_rawseti(L, -2, j + 1);
    }
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "fifteens");

  // Pairs
  lua_newtable(L);
  for (size_t i = 0; i < result.pairs.size(); ++i) {
    lua_newtable(L);
    for (size_t j = 0; j < result.pairs[i].size(); ++j) {
      lua_pushinteger(L, result.pairs[i][j] + 1); // Lua is 1-indexed
      lua_rawseti(L, -2, j + 1);
    }
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "pairs");

  // Runs
  lua_newtable(L);
  for (size_t i = 0; i < result.runs.size(); ++i) {
    lua_newtable(L);
    for (size_t j = 0; j < result.runs[i].size(); ++j) {
      lua_pushinteger(L, result.runs[i][j] + 1); // Lua is 1-indexed
      lua_rawseti(L, -2, j + 1);
    }
    lua_rawseti(L, -2, i + 1);
  }
  lua_setfield(L, -2, "runs");

  // Flush count
  lua_pushinteger(L, result.flushCount);
  lua_setfield(L, -2, "flushCount");

  // Nobs
  lua_pushboolean(L, result.hasNobs);
  lua_setfield(L, -2, "hasNobs");

  return 1;
}

static int Lua_CribbageScore(lua_State *L) {
  // First argument: 5 cards (4 hand + 1 cut)
  luaL_checktype(L, 1, LUA_TTABLE);

  // Optional: temp multiplier (default 0)
  float tempMult = static_cast<float>(luaL_optnumber(L, 2, 0.0));

  // Optional: perm multiplier (default 0)
  float permMult = static_cast<float>(luaL_optnumber(L, 3, 0.0));

  // Extract hand cards
  std::vector<Card> hand;
  for (int i = 1; i <= 4; ++i) {
    lua_rawgeti(L, 1, i);
    Card *card = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
    hand.push_back(*card);
    lua_pop(L, 1);
  }

  // Extract cut card
  lua_rawgeti(L, 1, 5);
  Card *cutCard = (Card *)luaL_checkudata(L, -1, "MagicHands.Card");
  lua_pop(L, 1);

  // Optional: boss rules (table of strings)
  std::vector<std::string> bossRules;
  if (lua_gettop(L) >= 4 && lua_istable(L, 4)) {
    size_t len = lua_rawlen(L, 4);
    for (size_t i = 1; i <= len; ++i) {
      lua_rawgeti(L, 4, i); // Push rule string
      if (lua_isstring(L, -1)) {
        bossRules.push_back(lua_tostring(L, -1));
      }
      lua_pop(L, 1);
    }
  }

  // Evaluate and score
  HandEvaluator::HandResult handResult =
      HandEvaluator::Evaluate(hand, *cutCard);
  ScoringEngine::ScoreResult scoreResult =
      ScoringEngine::CalculateScore(handResult, tempMult, permMult, bossRules);

  // Return score result as table
  lua_newtable(L);

  lua_pushinteger(L, scoreResult.fifteenChips);
  lua_setfield(L, -2, "fifteenChips");

  lua_pushinteger(L, scoreResult.pairChips);
  lua_setfield(L, -2, "pairChips");

  lua_pushinteger(L, scoreResult.runChips);
  lua_setfield(L, -2, "runChips");

  lua_pushinteger(L, scoreResult.flushChips);
  lua_setfield(L, -2, "flushChips");

  lua_pushinteger(L, scoreResult.nobsChips);
  lua_setfield(L, -2, "nobsChips");

  lua_pushinteger(L, scoreResult.baseChips);
  lua_setfield(L, -2, "baseChips");

  lua_pushnumber(L, scoreResult.tempMultiplier);
  lua_setfield(L, -2, "tempMultiplier");

  lua_pushnumber(L, scoreResult.permMultiplier);
  lua_setfield(L, -2, "permMultiplier");

  lua_pushinteger(L, scoreResult.finalScore);
  lua_setfield(L, -2, "finalScore");

  return 1;
}

void RegisterCribbageBindings(lua_State *L) {
  // Register cribbage global table
  lua_newtable(L);

  lua_pushcfunction(L, Lua_CribbageEvaluate);
  lua_setfield(L, -2, "evaluate");

  lua_pushcfunction(L, Lua_CribbageScore);
  lua_setfield(L, -2, "score");

  lua_setglobal(L, "cribbage");
}
