#include "gameplay/card/Card.h"
#include "gameplay/card/Deck.h"

extern "C" {
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
}

using namespace gameplay;

static const char *CARD_MT = "MagicHands.Card";
static const char *DECK_MT = "MagicHands.Deck";

// ===== Card Bindings =====

static int Lua_CardNew(lua_State *L) {
  const char *rankStr = luaL_checkstring(L, 1);
  const char *suitStr = luaL_checkstring(L, 2);

  // Parse rank
  Card::Rank rank = Card::Rank::Ace;
  if (strcmp(rankStr, "Ace") == 0 || strcmp(rankStr, "A") == 0)
    rank = Card::Rank::Ace;
  else if (strcmp(rankStr, "2") == 0)
    rank = Card::Rank::Two;
  else if (strcmp(rankStr, "3") == 0)
    rank = Card::Rank::Three;
  else if (strcmp(rankStr, "4") == 0)
    rank = Card::Rank::Four;
  else if (strcmp(rankStr, "5") == 0)
    rank = Card::Rank::Five;
  else if (strcmp(rankStr, "6") == 0)
    rank = Card::Rank::Six;
  else if (strcmp(rankStr, "7") == 0)
    rank = Card::Rank::Seven;
  else if (strcmp(rankStr, "8") == 0)
    rank = Card::Rank::Eight;
  else if (strcmp(rankStr, "9") == 0)
    rank = Card::Rank::Nine;
  else if (strcmp(rankStr, "10") == 0)
    rank = Card::Rank::Ten;
  else if (strcmp(rankStr, "Jack") == 0 || strcmp(rankStr, "J") == 0)
    rank = Card::Rank::Jack;
  else if (strcmp(rankStr, "Queen") == 0 || strcmp(rankStr, "Q") == 0)
    rank = Card::Rank::Queen;
  else if (strcmp(rankStr, "King") == 0 || strcmp(rankStr, "K") == 0)
    rank = Card::Rank::King;

  // Parse suit
  Card::Suit suit = Card::Suit::Hearts;
  if (strcmp(suitStr, "Hearts") == 0 || strcmp(suitStr, "H") == 0)
    suit = Card::Suit::Hearts;
  else if (strcmp(suitStr, "Diamonds") == 0 || strcmp(suitStr, "D") == 0)
    suit = Card::Suit::Diamonds;
  else if (strcmp(suitStr, "Clubs") == 0 || strcmp(suitStr, "C") == 0)
    suit = Card::Suit::Clubs;
  else if (strcmp(suitStr, "Spades") == 0 || strcmp(suitStr, "S") == 0)
    suit = Card::Suit::Spades;

  Card *card = (Card *)lua_newuserdata(L, sizeof(Card));
  new (card) Card(rank, suit);

  luaL_getmetatable(L, CARD_MT);
  lua_setmetatable(L, -2);

  return 1;
}

static int Lua_CardGetValue(lua_State *L) {
  Card *card = (Card *)luaL_checkudata(L, 1, CARD_MT);
  lua_pushinteger(L, card->getValue());
  return 1;
}

static int Lua_CardGetRank(lua_State *L) {
  Card *card = (Card *)luaL_checkudata(L, 1, CARD_MT);
  lua_pushinteger(L, card->getRankValue());
  return 1;
}

static int Lua_CardGetSuit(lua_State *L) {
  Card *card = (Card *)luaL_checkudata(L, 1, CARD_MT);
  lua_pushinteger(L, card->getSuitValue());
  return 1;
}

static int Lua_CardToString(lua_State *L) {
  Card *card = (Card *)luaL_checkudata(L, 1, CARD_MT);
  lua_pushstring(L, card->toString().c_str());
  return 1;
}

static int Lua_CardGC(lua_State *L) {
  Card *card = (Card *)luaL_checkudata(L, 1, CARD_MT);
  card->~Card();
  return 0;
}

// ===== Deck Bindings =====

static int Lua_DeckNew(lua_State *L) {
  uint64_t seed = 0;
  if (lua_gettop(L) >= 1) {
    seed = static_cast<uint64_t>(luaL_checkinteger(L, 1));
  }

  Deck *deck = (Deck *)lua_newuserdata(L, sizeof(Deck));
  new (deck) Deck(seed);

  luaL_getmetatable(L, DECK_MT);
  lua_setmetatable(L, -2);

  return 1;
}

static int Lua_DeckShuffle(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  deck->shuffle();
  return 0;
}

static int Lua_DeckDraw(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);

  if (deck->isEmpty()) {
    lua_pushnil(L);
    return 1;
  }

  Card card = deck->draw();
  Card *luaCard = (Card *)lua_newuserdata(L, sizeof(Card));
  new (luaCard) Card(card);

  luaL_getmetatable(L, CARD_MT);
  lua_setmetatable(L, -2);

  return 1;
}

static int Lua_DeckDrawMultiple(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  int count = luaL_checkinteger(L, 2);

  if (static_cast<size_t>(count) > deck->getSize()) {
    return luaL_error(L, "Not enough cards in deck");
  }

  std::vector<Card> cards = deck->drawMultiple(count);

  lua_createtable(L, count, 0);
  for (size_t i = 0; i < cards.size(); ++i) {
    Card *luaCard = (Card *)lua_newuserdata(L, sizeof(Card));
    new (luaCard) Card(cards[i]);

    luaL_getmetatable(L, CARD_MT);
    lua_setmetatable(L, -2);

    lua_rawseti(L, -2, i + 1);
  }

  return 1;
}

static int Lua_DeckReset(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  deck->reset();
  return 0;
}

static int Lua_DeckGetSize(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  lua_pushinteger(L, deck->getSize());
  return 1;
}

static int Lua_DeckIsEmpty(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  lua_pushboolean(L, deck->isEmpty());
  return 1;
}

static int Lua_DeckGC(lua_State *L) {
  Deck *deck = (Deck *)luaL_checkudata(L, 1, DECK_MT);
  deck->~Deck();
  return 0;
}

// ===== Registration =====

void RegisterCardBindings(lua_State *L) {
  // Card metatable
  luaL_newmetatable(L, CARD_MT);
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  lua_pushcfunction(L, Lua_CardGetValue);
  lua_setfield(L, -2, "getValue");

  lua_pushcfunction(L, Lua_CardGetRank);
  lua_setfield(L, -2, "getRank");

  lua_pushcfunction(L, Lua_CardGetSuit);
  lua_setfield(L, -2, "getSuit");

  lua_pushcfunction(L, Lua_CardToString);
  lua_setfield(L, -2, "toString");

  lua_pushcfunction(L, Lua_CardGC);
  lua_setfield(L, -2, "__gc");

  lua_pop(L, 1);

  // Card global table
  lua_newtable(L);
  lua_pushcfunction(L, Lua_CardNew);
  lua_setfield(L, -2, "new");
  lua_setglobal(L, "Card");

  // Deck metatable
  luaL_newmetatable(L, DECK_MT);
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  lua_pushcfunction(L, Lua_DeckShuffle);
  lua_setfield(L, -2, "shuffle");

  lua_pushcfunction(L, Lua_DeckDraw);
  lua_setfield(L, -2, "draw");

  lua_pushcfunction(L, Lua_DeckDrawMultiple);
  lua_setfield(L, -2, "drawMultiple");

  lua_pushcfunction(L, Lua_DeckReset);
  lua_setfield(L, -2, "reset");

  lua_pushcfunction(L, Lua_DeckGetSize);
  lua_setfield(L, -2, "getSize");

  lua_pushcfunction(L, Lua_DeckIsEmpty);
  lua_setfield(L, -2, "isEmpty");

  lua_pushcfunction(L, Lua_DeckGC);
  lua_setfield(L, -2, "__gc");

  lua_pop(L, 1);

  // Deck global table
  lua_newtable(L);
  lua_pushcfunction(L, Lua_DeckNew);
  lua_setfield(L, -2, "new");
  lua_setglobal(L, "Deck");
}
