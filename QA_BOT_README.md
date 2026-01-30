# 🤖 Magic Hands QA Automation Bot

**Version**: 1.0  
**Status**: ✅ Implementation Complete  
**Last Updated**: January 30, 2026

---

## Quick Start

```bash
# Navigate to build directory
cd build

# Run with default settings (100 runs, Random strategy)
./MagicHand --autoplay

# Run with custom configuration
./MagicHand --autoplay --autoplay-runs=500 --autoplay-strategy=FifteenEngine

# Results will be saved to qa_results/
```

---

## What It Does

The QA Automation Bot plays Magic Hands autonomously to:

- ✅ **Find Bugs** - Catches crashes, errors, and invalid game states
- ✅ **Test Balance** - Validates scoring, difficulty, and progression
- ✅ **Stress Test** - Runs hundreds of games overnight
- ✅ **Collect Data** - Generates JSON reports for analysis
- ✅ **Document Issues** - Takes screenshots on errors

---

## Command Line Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--autoplay` | Enable QA bot mode | (required) |
| `--autoplay-runs=N` | Number of games to play | 100 |
| `--autoplay-strategy=NAME` | AI strategy to use | Random |

### Available Strategies

- **Random** - Makes random valid decisions (baseline testing)
- **FifteenEngine** - Optimizes for fifteen scoring patterns
- **PairExplosion** - Focuses on pair-based builds

---

## Output Files

### Directory Structure

```
qa_results/
├── run_20260130_182530_001.json
├── run_20260130_182530_002.json
├── run_20260130_182530_003.json
├── screenshots/
│   ├── error_1738355130.png
│   ├── run_20260130_182530_001_final.png
│   └── run_20260130_182530_002_final.png
└── summary_20260130_182530.json (generated after all runs)
```

### JSON Output Structure

Each run generates a comprehensive JSON file:

```json
{
  "runId": "run_20260130_182530_001",
  "startTime": 1738355130,
  "endTime": 1738355145,
  "durationSeconds": 15,
  "strategy": "Random",
  
  "outcome": "loss",
  "actReached": 2,
  "blindReached": 2,
  "finalScore": 1245,
  
  "handsPlayed": 12,
  "bestHandScore": 120,
  "averageHandScore": 85.5,
  
  "jokersAcquired": ["fifteen_fever", "pair_power"],
  "jokersStacked": {"fifteen_fever": 2},
  "planetsAcquired": ["planet_fifteen"],
  
  "errors": [],
  "warnings": [],
  "logicErrors": [],
  
  "avgFrameTime": 12.5,
  "maxFrameTime": 45.2,
  
  "decisions": [
    {
      "type": "crib_selection",
      "timestamp": 1738355131,
      "selected": [0, 3],
      "reasoning": "Strategy: Random"
    }
  ]
}
```

---

## Features

### Error Detection

1. **Console Errors** - Captures ERROR/WARN from Logger
2. **Lua Runtime Errors** - Catches pcall failures with stack traces
3. **Logic Errors** - Detects:
   - Negative gold
   - Invalid hand sizes
   - Negative hands/discards remaining
4. **Performance Issues** - Flags frame times > 33ms (below 30 FPS)

### Statistics Tracking

- **Basic**: Outcome, Act/Blind reached, score, hands played
- **Collections**: Jokers, planets, warps, imprints acquired
- **Scoring**: Best/worst/average hand scores, crib scores
- **Decisions**: Every bot decision with reasoning
- **Performance**: Frame times, averages, peaks

### AI Strategies

Each strategy implements:
- `selectCardsForCrib(hand)` - Choose 2 cards for crib
- `selectCardsToPlay(hand)` - Choose 4 cards to play
- `selectShopItem(items, gold)` - Purchase logic
- `shouldReroll(gold, items)` - Reroll decision
- `shouldSellJoker(jokers)` - Sell logic

---

## Architecture

### File Structure

```
content/scripts/Systems/
├── AutoPlay.lua                # Main controller
├── AutoPlayStrategies.lua      # AI decision-making
├── AutoPlayStats.lua           # Statistics collector
└── AutoPlayErrors.lua          # Error detection

src/
├── core/main.cpp               # CLI flag parsing
├── graphics/SpriteRenderer.*   # Screenshot support
└── scripting/LuaBindings.cpp   # Lua bindings
```

### Control Flow

```
main.cpp
  ↓ (parses --autoplay flags)
main.lua
  ↓ (checks AUTOPLAY_MODE)
GameScene.lua
  ↓ (initializes AutoPlay)
AutoPlay.lua
  ├─→ AutoPlayStrategies.lua (makes decisions)
  ├─→ AutoPlayStats.lua (tracks data)
  └─→ AutoPlayErrors.lua (monitors errors)
  ↓
qa_results/*.json
```

---

## Example Session

```bash
$ ./MagicHand --autoplay --autoplay-runs=10 --autoplay-strategy=FifteenEngine

=================================================
===    Magic Hands QA AutoPlay Bot v1.0      ===
=================================================
Total Runs: 10
Strategy: FifteenEngine
=================================================

╔════════════════════════════════════════════╗
║  Starting Run 1 / 10
╚════════════════════════════════════════════╝
Run ID: run_20260130_182530_001
Strategy: FifteenEngine

Bot added 2 card(s) to crib
Bot playing 4 cards
Hand #1 scored: 45 points
Hand #2 scored: 67 points
...
Blind cleared!
Bot purchased: The Fifteen
Bot skipping shop
...

╔════════════════════════════════════════════╗
║  Run 1 Complete: LOSS
╚════════════════════════════════════════════╝

Run Summary:
  Outcome: loss
  Act Reached: 2
  Blind Reached: 1
  Final Score: 845
  Hands Played: 8
  Best Hand: 120
  Errors: 0
  Warnings: 2
  Duration: 15s
  Saved: qa_results/run_20260130_182530_001.json
  Screenshot: qa_results/screenshots/run_20260130_182530_001_final.png

...
[Runs 2-10]
...

╔════════════════════════════════════════════╗
║     All Runs Complete - Generating        ║
║            Summary Report                  ║
╚════════════════════════════════════════════╝

Total Runs: 10
Results saved to: qa_results/

╔════════════════════════════════════════════╗
║      AutoPlay QA Bot Shutdown Complete    ║
╚════════════════════════════════════════════╝
```

---

## Analysis Tools (Future)

### Planned Python Scripts

```bash
# Parse all runs and generate summary
python tools/qa_analysis/analyze_runs.py qa_results/

# Plot win rate, score distribution, etc.
python tools/qa_analysis/plot_stats.py qa_results/

# Compare two builds (A/B testing)
python tools/qa_analysis/compare_builds.py qa_results_v1/ qa_results_v2/
```

---

## Integration with GameScene

The bot integrates minimally with game code:

```lua
-- In GameScene.lua (lines 19-24)
local AutoPlay = nil
if AUTOPLAY_MODE then
    AutoPlay = require("Systems/AutoPlay")
    print("AutoPlay Mode: ENABLED")
end

-- In GameScene:init() (lines 106-109)
if AutoPlay and AUTOPLAY_MODE then
    AutoPlay:init(AUTOPLAY_RUNS or 100, AUTOPLAY_STRATEGY or "Random")
end

-- In GameScene:update(dt) (lines 292-296)
if AutoPlay and AutoPlay.enabled then
    AutoPlay:update(self, dt)
end
```

**Result**: Zero impact when not using `--autoplay` flag.

---

## Adding New Strategies

Create a new strategy in `AutoPlayStrategies.lua`:

```lua
AutoPlayStrategies.MyStrategy = {
    name = "MyStrategy",
    
    selectCardsForCrib = function(self, hand)
        -- Your logic here
        return {1, 2}  -- Indices of cards
    end,
    
    selectCardsToPlay = function(self, hand)
        -- Your logic here
        return {1, 2, 3, 4}
    end,
    
    selectShopItem = function(self, shopItems, gold)
        -- Your logic here
        return 1  -- Index of item, or nil
    end,
    
    shouldReroll = function(self, gold, shopItems)
        -- Your logic here
        return false
    end,
    
    shouldSellJoker = function(self, jokers)
        return false
    end
}

-- Register it
function AutoPlayStrategies:getStrategy(name)
    if name == "MyStrategy" then
        return self.MyStrategy
    elseif ...
end
```

Then use it:
```bash
./MagicHand --autoplay --autoplay-strategy=MyStrategy
```

---

## Known Limitations

1. **Screenshot Incomplete**
   - C++ implementation is a stub
   - Needs SDL_GPU texture readback
   - Currently returns `false`

2. **No Visual Rendering**
   - Bot runs in "turbo mode" (0.1s delays)
   - Not designed for watching
   - Use normal game for visual debugging

3. **Limited AI**
   - Strategies are rule-based, not learning
   - Random strategy doesn't try to win
   - Best for regression testing, not gameplay testing

4. **File I/O Dependent**
   - Requires `files.saveFile()` binding
   - Will warn if not available
   - Data will be lost without file saving

---

## Troubleshooting

### Bot doesn't start
- Check `AUTOPLAY_MODE` global is true
- Verify all `AutoPlay*.lua` files exist
- Check console for Lua errors

### No output files
- Check `files.saveFile()` is available
- Verify write permissions on `qa_results/`
- Look for error messages in console

### Game crashes
- Check console for error before crash
- Look for screenshot in `qa_results/screenshots/`
- Review last run's JSON for patterns

### Strange decisions
- Check which strategy is active
- Review decision log in JSON output
- Verify strategy logic is correct

---

## Performance

### Benchmarks (Estimated)

- **Turbo Mode**: ~10-20 seconds per run
- **100 Runs**: ~20-30 minutes
- **1000 Runs**: ~3-5 hours
- **Overnight**: ~5000-10000 runs

### Resource Usage

- **CPU**: ~50-80% (single core)
- **Memory**: ~200-400MB
- **Disk**: ~100KB per run (JSON)
- **Screenshots**: ~500KB each (if enabled)

---

## Development

### Testing the Bot

```bash
# Quick test (1 run)
./MagicHand --autoplay --autoplay-runs=1

# Medium test (10 runs, ~3 minutes)
./MagicHand --autoplay --autoplay-runs=10

# Full test (100 runs, ~30 minutes)
./MagicHand --autoplay --autoplay-runs=100
```

### Debugging

Add debug prints to `AutoPlay.lua`:

```lua
function AutoPlay:handlePlayPhase(gameScene)
    print("DEBUG: Play phase, hand size: " .. #gameScene.hand)
    -- ... rest of logic
end
```

---

## Credits

- **Architecture**: Lua integration for direct game access
- **Strategies**: Rule-based AI (Random, FifteenEngine, PairExplosion)
- **Statistics**: Comprehensive tracking system
- **Error Detection**: Multi-layered error capture

---

## Future Enhancements

- [ ] Complete screenshot GPU readback
- [ ] Python analysis dashboard
- [ ] More AI strategies (RunMaster, Economic, etc.)
- [ ] Machine learning-based strategies
- [ ] Real-time web dashboard
- [ ] CI/CD integration
- [ ] Parallel execution (multiple instances)
- [ ] Visual regression testing
- [ ] Automated bug reports (GitHub issues)
- [ ] Performance profiling integration

---

**Ready to use!** 🚀

For questions or issues, see `QA_BOT_IMPLEMENTATION.md` for implementation details.
