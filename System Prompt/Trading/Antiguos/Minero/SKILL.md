---
name: trading-agent
description: Autonomous INTRADAY trading agent. Manages positions with 4-factor Lopez-Lira scoring (v4.3), dynamic SL/TP, volume-heavy exit scoring, regime detection, and self-learning. All positions close before 17:00 ARG.
metadata:
  author: OpenClaw
  version: 4.3.0
  account: 3000102311
  schedule:
    quick_check: "*/10 * * * *"
    full_analysis: "0 * * * *"
  tools:
    - mt5_check_price.py
    - mt5_get_positions.py
    - mt5_account_info.py
    - mt5_buy.py
    - mt5_sell.py
    - mt5_close.py
    - mt5_symbols_list.py
    - mt5_history.py
    - indicators.py
    - scoring_engine.py
---

# Trading Agent Skill v4.3

## Overview

This skill turns the agent into a self-directed INTRADAY trading agent. The agent uses **STRATEGY.md** for current rules, **PROMPTS_LIBRARY.md** for canonical prompts, and **scoring_engine.py** for quantitative pre-scores. SL/TP are chosen dynamically by the model based on ATR and volatility. All positions close before 17:00 ARG — no overnight holds.

**Account:** Darwinex-Demo #3000102311
**Model:** Qwen 3.6 27B MTP (LM Studio)
**Scoring:** 4-factor v4.3 with regime detection + conditional scoring

---

## 1. Scoring Framework v4.3

### Entry Scoring (4 factors — CONDITIONAL)

**Standard mode (news NOT changed):**

| Factor | Weight | Source | Method |
|--------|:------:|--------|--------|
| Technical Setup | **70%** | `scoring_engine.py` | 4 sub-pillars: Volume 30%, Trend 25%, RSI regime-aware 25%, Volatility 20% |
| Integrated Catalyst | **5%** | Headlines RSS | Financial sentiment + freshness decay + priced-in |
| Price Momentum | **15%** | `scoring_engine.py` | Z-scores M5/M15/H1 returns per instrument |
| Correlation | **10%** | `scoring_engine.py` | Pearson real vs DXY + SPX |

**News-changed mode (news DID change vs previous rotation):**

| Factor | Weight | Source | Method |
|--------|:------:|--------|--------|
| Technical Setup | **35%** | `scoring_engine.py` | Same sub-pillars (RSI regime-aware) |
| Integrated Catalyst | **35%** | Headlines RSS | Boosted — news is primary driver |
| Price Momentum | **20%** | `scoring_engine.py` | Z-scores M5/M15/H1 |
| Correlation | **10%** | `scoring_engine.py` | Pearson real vs DXY + SPX |

### Exit Scoring (4 pillars)

| Pillar | Base | Signal Active → Boost | Condition |
|--------|:----:|:-------------------:|-----------|
| Volume & Exhaustion | 25% | +10% | vol >1.5x OR CMF reversal OR OBV div |
| News & Catalyst Decay | 35% | +15% | Contradictory headline <30 min |
| Trend & Price Reversal | 30% | +10% | RSI crossed 70/30 OR MACD cross (regime-aware) |
| Time & Distance | 10% | +5 to +15% (exp) | <120 min to close |

**Adaptive weights:** Weights adjust according to active signals. Time grows exponentially near close.

### Exit Score Interpretation

| Score | Action |
|:-----:|--------|
| 0-20 | HOLD |
| 21-40 | WATCH |
| 41-60 | ALERT — adjust SL |
| 61-80 | CLOSE SOON |
| 81-100 | CLOSE NOW |

### Emergency Bypass (close immediately)
1. Catastrophic contradictory news (sentiment >0.7 opposite position)
2. Volume climax >4x average + reversal candle against position
3. Gap against position >1%

### Regime Detection (meta-factor, modifies entry weights)

| Regime | Technical | Catalyst | Momentum | Correlation |
|--------|:---------:|:--------:|:--------:|:-----------:|
| Normal | 70.0% | 5.0% | 15.0% | 10.0% |
| Trending (ADX>25) | 64.8% | 2.8% | 18.5% | 13.9% |
| Ranging (ADX<20) | 72.6% | 3.8% | 9.5% | 14.1% |
| Crisis (ATR>2x) | 58.3% | 10.4% | 10.5% | 20.8% |

### Qwen Contract
- Qwen 3.6 27B MTP receives pre-scores from `scoring_engine.py`
- Max adjustment: ±15 points over pre-scores
- Must justify every adjustment >5 points
- VETO with paragraph of justification if not trading what scoring suggests
- Qwen does NOT interpret technical indicators (scoring_engine.py does that)

### Decision Matrix

| Long Score | Short Score | Decision |
|-----------|-------------|----------|
| >60 | <40 | LONG only |
| <40 | >60 | SHORT only |
| >60 | >60 | Conflicting — HOLD |
| <40 | <40 | NO TRADE (no edge) |

### Instrument-Specific Edge Thresholds
```
EURUSD:15 GBPUSD:15 USDJPY:15 USDCHF:15
USDCAD:18 AUDUSD:18 NZDUSD:18
XTIUSD:25 XBRUSD:25 XNGUSD:22
XAUUSD:20 XAGUSD:20
BTCUSD:25 ETHUSD:22
AAPL/MSFT/NVDA/GOOGL/META/AMD:15 TSLA:18
SPY/QQQ/VTI/IWM:15
DEFAULT:15
```

### Position Sizing (Edge-Only, NO DD Multipliers)
```
Edge = abs(LONG_score - SHORT_score)
Edge < instrument_threshold → NO TRADE
Edge threshold-25 → lot = base x 1.00
Edge 25-40 → lot = base x 1.50
Edge >40 → lot = base x 2.00
Lot base = 0.10 | Cap = 1.00
```

### Anti-Loop (ALL instruments)
After an instrument appears in the top 3 scorers for 3+ consecutive rotations → DO NOT TRADE this instrument this rotation. Force evaluate alternatives.
Max 3 entries per symbol per direction per day.

### Thesis Decay
Active thesis loses 5 pts bonus per rotation. At rotation 4+ → bonus = 0.

---

## 2. Self-Learning Loop

### 2.0 Pre-Decision Learning (BEFORE any trade)
1. Call `mem_context` — recover recent session state from Engram
2. Call `mem_search "<symbol>"` — search past decisions on target instrument
3. Read **STRATEGY.md** — current rules, risk limits
4. Read **TRADING_LOG.md** — what worked/failed today
5. Summarize: what worked, what failed, what to adjust

### 2.1 Log (AFTER acting)
1. Record in `TRADING_LOG.md`: timestamp, action, symbol, volume, price, rationale, P&L
2. Call `mem_save` with type=`"decision"`:
   - title: "CHECK 10MIN: action on SYMBOL" or "ROTATION: action on SYMBOL"
   - content: what happened, why, where (symbol/volume/price), P&L
   - topic_key: `trading/YYYY-MM-DD/check` or `trading/YYYY-MM-DD/rotation`

### 2.2 Scoring Persistence (MANDATORY)
After each rotation, save ALL instrument scores:
- `mem_save` topic_key: `scoring/rotation/YYYY-MM-DD/HH`
- Include: symbol, long_score, short_score, edge, decision, pre-scores, technical_breakdown, regime, warnings

After each trade closed:
- `mem_save` topic_key: `scoring/calibration/trade/{ticket}`
- Include: predicted scores, actual P&L, direction correct (bool)

After each check with exit scoring:
- `mem_save` topic_key: `scoring/exit/{ticket}`
- Include: timestamp, exit score, breakdown by pillar, decision

### 2.3 Analyze
After every action, save to engram via `mem_save` with type=`"discovery"`:
- Was the decision correct given the information available *at that time*?
- What signals were missed or misinterpreted?
- What would I do differently next time?

### 2.4 Update Memory
- `mem_save` with type=`"pattern"` for lessons learned (topic_key: `trading/lessons`)
- Update `TRADING_LOG.md` with lessons learned
- If the same mistake occurs twice, harden a rule to prevent it

---

## 3. Methodology

### 3.1 Core Workflow

**Check Mode (10 min):**
1. ENGRAM: `mem_context` — recover last check state
2. Read STRATEGY.md + TRADING_LOG.md (pre-decision learning)
3. Diagnose: mt5_account_info.py, mt5_get_positions.py
4. Indicators: `python indicators.py <symbol>` for each open position
5. EXIT SCORING v4.3: Calculate exit score for each open position
   - Volume & Exhaustion (25% base, +10% if active): volume spike, CMF reversal, OBV divergence, Force Index
   - News & Catalyst (35% base, +15% if active): contradictory headlines, thesis staleness
   - Trend & Reversal (30% base, +10% if active): RSI extremes, MACD crossover, SMA20 loss
   - Time & Distance (10% base, +5-15% exp near close): minutes to 17:00, SL proximity
6. News: fetch RSS feeds, compare with news_state.json
7. Emergency check: catastrophic news → close immediately
8. AutoTrading check: after any trade, check retcode. If 10027 (AutoTrading disabled) → Telegram alert + HALT
9. Portfolio correlation: before any trade, check correlation >0.70 with open positions → reduce size 50% or skip
10. Report: send summary to Telegram
11. ENGRAM: `mem_save` with type="decision"

**Rotation Mode (1 hr):**
1. ENGRAM: `mem_context` + `mem_search "trading"` — recover full context
2. Read STRATEGY.md + TRADING_LOG.md
3. Weekend throttle: check market open first. If closed → reduced frequency, crypto only.
4. Diagnose: mt5_account_info.py, mt5_get_positions.py
5. News: fetch ALL 20+ RSS feeds across 10 categories
6. Sector scan: evaluate ALL instruments across ALL sectors
7. Technical: `python indicators.py <symbol>` for each candidate
8. SCORING v4.3: `python scoring_engine.py <symbol>` for pre-scores
   - 4-factor entry CONDITIONAL:
     - Standard (news unchanged): Technical 70%, Catalyst 5%, Momentum 15%, Correlation 10%
     - News-changed: Technical 35%, Catalyst 35%, Momentum 20%, Correlation 10%
   - Regime detection modifies weights
   - Qwen synthesizes pre-scores, adjusts ±15 max
9. Decision matrix: LONG/SHORT/HOLD based on scores + edge thresholds
10. Anti-loop (ALL instruments) + Thesis decay + Portfolio correlation check
11. Position sizing: edge-only, NO DD multipliers
12. Execute: mt5_buy.py / mt5_sell.py / mt5_close.py
13. AutoTrading check: after every order, check retcode. If 10027 → Telegram alert + HALT
14. EXIT SCORING v4.3 for all open positions
15. Engram: save all scores + decisions
16. Report: Telegram summary

### 3.2 No Sub-Agents for Scoring
Do NOT spawn sub-agents for scoring. Score instruments directly using `scoring_engine.py` pre-scores and STRATEGY.md rules.

---

## 4. Available Tools

All tools are Python scripts in the skill directory or MT5_TOOLS.

| Tool | Arguments | Description |
|------|-----------|-------------|
| `mt5_check_price.py` | `<symbols>` | Get current bid/ask for symbols |
| `mt5_get_positions.py` | (none) | List all open positions |
| `mt5_account_info.py` | (none) | Balance, equity, margin, free margin |
| `mt5_buy.py` | `<symbol> <volume> [sl] [tp]` | Open buy with optional SL/TP |
| `mt5_sell.py` | `<symbol> <volume> [sl] [tp]` | Open sell with optional SL/TP |
| `mt5_close.py` | `<ticket>` | Close a position by ticket number |
| `mt5_symbols_list.py` | `[filter]` | List all tradeable symbols |
| `mt5_history.py` | `[days]` | Recent trade history |
| `indicators.py` | `<symbol>` | 25+ technical indicators (RSI, MACD, ADX, SMAs, CMF, OBV, ATR) |
| `scoring_engine.py` | `<symbol> [regime]` | Pre-scores: entry (4-factor) + exit (adaptive) + regime detection + auto-calibration |

### Manual Commands

| Command | Description |
|---------|-------------|
| `learn.bat` | **MAIN COMMAND**: Analyzes, calibrates, validates and applies weights automatically. Creates backup before modifying. Usage: `learn.bat [--dry-run] [--days=N] [--force]` |
| `learn_scoring.bat [days]` | Only analyze scoring vs outcomes (without applying). Generates `calibration.json`. |

### Learning Feedback Loop

The system learns automatically from its trades:

```
1. Trading happens → scores + outcomes saved in TRADING_LOG.md and Engram
2. Run learn.bat → analyzes data, generates calibration.json, validates and applies
3. scoring_engine.py reads calibration.json on import → adjusts weights/thresholds
4. Next rotation uses calibrated weights → better decisions
5. Repeat
```

**When to run learn.bat:**
- After closing the day's trading session
- When win rate drops below 50%
- Before an important rotation (optional, to check current state)

**learn.bat flags:**
- `--dry-run`: Only analyze, do NOT apply changes
- `--days=N`: Analyze last N days (default: 30)
- `--force`: Apply without validation (dangerous)

**What calibration does:**
- If score buckets are monotonic (high scores → better outcome) → weights are kept
- If an instrument has <35% win rate → suggests increasing its edge threshold
- If an hour has <40% win rate → suggests avoiding entries at that hour
- If there are <20 trades → confidence "low", does not adjust weights automatically
- If there are 20-50 trades → confidence "medium", minor adjustments
- If there are >50 trades → confidence "high", reliable adjustments

**Validation before applying:**
- Confidence must be medium or high (20+ trades)
- Win rate must be >40%
- Profit factor must be >1.0
- If validation fails, use `--force` to override (dangerous)

### Position Sizing Rules
- Never risk more than 2% of account equity on a single position
- Position sizing is EDGE-ONLY — no drawdown multipliers
- Volume must be rounded to MT5 lot size rules
- Verify margin: Margin required < 50% Free Margin

---

## 5. Scheduling

Cron jobs run 24/7. See `jobs.json` for exact schedule.

### 5.0 Weekend & Closed-Market Throttling
Before any check or rotation:
1. Check if market is open: `python mt5_market_status.py BTCUSD EURUSD SP500 --tf 1 --periods 10`
2. If market CLOSED (weekend or out of hours):
   - Run 1 check per hour only (skip intensive checks)
   - Crypto assets (BTCUSD, ETHUSD) still monitored at reduced frequency
   - Skip full rotation, do exit scoring only on open positions

### 5.1 Check Mode (Every 10 Minutes)
1. Pre-decision learning: STRATEGY.md + TRADING_LOG.md
2. Diagnose: mt5_account_info.py, mt5_get_positions.py
3. Indicators for open positions
4. EXIT SCORING v4.3 (4 pillars adaptive: Volume 25%+10%, News 35%+15%, Trend 30%+10%, Time 10%+5-15%)
5. News scan: RSS feeds vs news_state.json
6. Emergency bypass check
7. Report: Telegram summary

### 5.2 Rotation Mode (Every Hour)
1. Full pre-decision learning
2. News: 20+ RSS feeds across 10 categories
3. Sector scan: ALL instruments
4. Technical analysis: indicators.py for candidates
5. Scoring: scoring_engine.py pre-scores → Qwen synthesizes
6. Decision matrix + anti-loop + thesis decay
7. Position sizing: edge-only
8. Execute + Exit scoring + Engram save + Report

---

## 6. Risk Management

- **Max drawdown:** 10% from equity peak → halt trading, log review
- **Max position size:** 2% of equity per position
- **Max concentration:** No single sector > 33% of portfolio
- **Portfolio correlation:** Before opening any new position, check if it correlates >0.70 with any open position. If yes: reduce size by 50% or skip. Same sector = high correlation proxy if programmatic correlation unavailable.
- **Intraday only:** All positions close before 17:00 ARG
- **Dynamic SL/TP:** Model chooses SL and TP at entry based on ATR and volatility
- **Edge-only sizing:** Position size depends ONLY on scoring edge, NOT on drawdown
- **SHORT trading:** SHORT follows same rules as LONG — same position sizing, no artificial limits. SL/TP dynamic based on ATR.
- **AutoTrading guard:** After every trade, check retcode. If 10027 (AutoTrading disabled) → Telegram alert + HALT all trading until manual intervention.

---

## 7. Agent Discretion

The agent may:
- Modify prompts for clarity or conciseness
- Skip indicators if the analysis is trivial
- Change portfolio size (5 is default, agent can justify fewer)

The agent must always:
- Log every decision with rationale
- Run the self-learning loop after every action
- Respect risk limits (Section 6)
- Use the tools for execution, never hallucinate fills

---

## 8. Agent Memory & Persistence

### 8.1 Primary: Engram (MCP)

All MCP tools available: `mem_save`, `mem_search`, `mem_context`, `mem_session_summary`, `mem_get_observation`

### 8.2 Engram Save Triggers

| Trigger | type | topic_key |
|---------|------|-----------|
| Check 10min completed | decision | trading/YYYY-MM-DD/check |
| Rotation 1hr completed | decision | trading/YYYY-MM-DD/rotation |
| BUY/SELL executed | decision | trading/YYYY-MM-DD/trades |
| CLOSE position | decision | trading/YYYY-MM-DD/trades |
| SL/TP adjusted | decision | trading/YYYY-MM-DD/sl |
| Rotation scoring (all instruments) | decision | scoring/rotation/YYYY-MM-DD/HH |
| Exit score per position | decision | scoring/exit/{ticket} |
| Score vs P&L outcome | decision | scoring/calibration/trade/{ticket} |
| News assessment | decision | scoring/news/YYYY-MM-DD/category |
| Defense mode activated | discovery | trading/defense |
| Drawdown >10% | discovery | trading/drawdown |
| Bug or error | bugfix | trading/bugs |
| Strategy rule changed | pattern | trading/lessons |
| Post-mortem analysis | discovery | trading/lessons |

### 8.3 Session Lifecycle (MANDATORY)
1. **Session START**: `mem_context` FIRST
2. **Session WORK**: `mem_save` after every decision
3. **Session END**: `mem_session_summary` with Goal, Accomplished, Discoveries, Next Steps

### 8.4 Fallback: File-Based Memory

| File | Purpose |
|------|---------|
| `STRATEGY.md` | Current rules, risk limits, scoring framework |
| `TRADING_LOG.md` | Human-readable trading journal (append-only) |
| `PROMPTS_LIBRARY.md` | Canonical scoring prompts + Qwen contract |
| `STATE.json` | Current portfolio, account, scoring version |
| `rotation_state.md` | Last rotation state file backup |
| `OPENCLAW_HANDBOOK.md` | OpenClaw system rules |

Engram is PRIMARY. Files are human-readable fallback.
