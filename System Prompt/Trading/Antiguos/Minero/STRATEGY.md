# STRATEGY NOTES — SUDA-QUANT v4.3 (INTRADAY)

**Account:** Darwinex-Demo #3000102311  
**Model:** Qwen 3.6 27B MTP (LM Studio)  
**All positions close before 17:00 ART. No overnight holds.**

---

## Scoring Framework v4.3

### Entry Scoring (4 Factors) — CONDITIONAL WEIGHTS

**Standard mode** (news NOT changed vs previous rotation):

| Factor | Weight | Source | What it measures |
|--------|:------:|--------|------------------|
| Technical Setup | **70%** | `scoring_engine.py` | Volume (30%) + Trend (25%) + RSI (25%) + Volatility (20%) |
| Integrated Catalyst | **5%** | Headlines RSS | Financial sentiment + freshness decay + priced-in tracking |
| Price Momentum | **15%** | `scoring_engine.py` | Z-scores M5/M15/H1 returns per instrument |
| Correlation | **10%** | `scoring_engine.py` | Pearson real vs DXY + SPX (no subjective judgment) |

**News-changed mode** (news DID change vs previous rotation):

| Factor | Weight | Source | What it measures |
|--------|:------:|--------|------------------|
| Technical Setup | **35%** | `scoring_engine.py` | Volume (30%) + Trend (25%) + RSI (25%) + Volatility (20%) |
| Integrated Catalyst | **35%** | Headlines RSS | Financial sentiment + freshness decay + priced-in tracking |
| Price Momentum | **20%** | `scoring_engine.py` | Z-scores M5/M15/H1 returns per instrument |
| Correlation | **10%** | `scoring_engine.py` | Pearson real vs DXY + SPX (no subjective judgment) |

### News Change Detection

`scoring_engine.py` automatically detects if news changed between rotations using **semantic topic fingerprinting**:
1. Filters only HIGH/CRITICAL impact headlines (ignores MEDIUM/LOW noise)
2. Groups headlines by topic (oil, geopolitics, macro, tech, etc.) and computes avg sentiment per topic
3. Compares topic fingerprints with previous state stored in `news_state.json`
4. If >30% of topics have sentiment shift >0.3 → **news_changed = True** → activates catalyst-boosted weights
5. If topics stable → **news_changed = False** → uses standard weights
6. **2-hour cooldown**: news_changed cannot re-trigger within 120 minutes (except CRITICAL impact + strong sentiment bypass)
7. First rotation (no previous state) → treats as news_changed = True

The `news_changed` flag is persisted in `scoring_history.jsonl` per instrument.

### Exit Scoring (4 Pillars)

**All technical indicators are evaluated on M5 + M15 + H1.**

| Pillar | Base | Signal Active → Boost | Condition |
|--------|:----:|:-------------------:|-----------|
| Volume & Exhaustion | 25% | +10% | vol >1.5x OR CMF reversal OR OBV divergence |
| News & Catalyst Decay | 35% | +15% | Contradictory headline <30 min |
| Trend & Price Reversal | 30% | +10% | RSI crossed 70/30 OR MACD crossover |
| Time & Distance | 10% | +5 to +15% (exp) | <120 min to 17:00 ART |

**Adaptive weights:** Weights adjust automatically based on which signals are ACTIVE. Active signal steals weight from inactive pillars. Time grows exponentially near close.

### Exit Score Interpretation

| Score | Action |
|:-----:|--------|
| 0-20 | HOLD |
| 21-40 | WATCH |
| 41-60 | ALERT — adjust SL |
| 61-80 | CLOSE SOON |
| 81-100 | CLOSE NOW |

### ⚠️ VOLUME ON DARWINEX CFDs — IMPORTANT
- `mt5_check_price.py` uses `SymbolInfoTick().volume` → ALWAYS returns 0 on Darwinex CFDs
- `indicators.py` and `mt5_market_status.py` use `copy_rates_from_pos()` with **REAL tick_volume**
- To detect if the market is active: use `mt5_market_status.py`, NOT mt5_check_price.py Volume=0
- tick_volume is a valid proxy of market activity on CFDs (real_volume is always 0)

### Emergency Bypass (Immediate close without exit scoring)

1. Catastrophic contradictory news (sentiment >0.7 opposite position)
2. Volume climax >4x average + reversal candle against position
3. Gap against position >1%

### Regime Detection (dynamically modifies entry weights)

Regime multipliers are applied ON TOP of base weights (standard or news-changed).

| Regime | Technical | Catalyst | Momentum | Correlation |
|--------|:---------:|:--------:|:--------:|:-----------:|
| Normal | 1.00x | 1.00x | 1.00x | 1.00x |
| Trending (ADX>25) | 1.00x | 0.60x | 1.33x | 1.50x |
| Ranging (ADX<20) | 1.10x | 0.80x | 0.67x | 1.50x |
| Crisis (ATR>2x) | 0.80x | 2.00x | 0.67x | 2.00x |

Example: Crisis + News Changed → base (35/35/20/10) × crisis multipliers → normalized to 100%

### Qwen Contract

- Qwen 3.6 27B MTP receives programmatic pre-scores from `scoring_engine.py`
- Max adjustment: ±15 points over pre-scores
- Justify every adjustment >5 points
- VETO with justification paragraph if not trading what scoring suggests
- Qwen does NOT interpret technical indicators (scoring_engine.py does that)
- Qwen synthesizes semantic factors: geopolitical narratives, Price Momentum, catalyst severity

### Scoring Decision Matrix

| Long Score | Short Score | Decision |
|-----------|-------------|----------|
| >60 | <40 | LONG only |
| <40 | >60 | SHORT only |
| >60 | >60 | Conflicting — HOLD |
| <40 | <40 | NO TRADE (no edge) |
| 40-60 | 40-60 | NEUTRAL / HOLD |

### Instrument-Specific Edge Thresholds
```
EURUSD:15 GBPUSD:15 USDJPY:15 USDCHF:15
USDCAD:18 AUDUSD:18 NZDUSD:18
XTIUSD:25 XBRUSD:25 XNGUSD:22
XAUUSD:20 XAGUSD:20
BTCUSD:25 ETHUSD:22
AAPL/MSFT/NVDA/GOOGL/META/AMD:15 TSLA:18 AMZN:15 NFLX:15
SPY/QQQ/VTI/IWM:15 XLE/XLV/XLK/XLF/XLI/XLU:15
ZN/ZB/ZF:15
DEFAULT:15
```

### Instrument Lists by Sector

**Commodities:** XTIUSD, XAUUSD, XAGUSD, XNGUSD, XBRUSD  
**Forex:** EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD  
**Indices (CFDs):** SP500, NDX, DJI, UK100, FCHI40, WS30, GDAXI  
**US Equities — Tech (CFDs):** AAPL, MSFT, NVDA, GOOGL, META, AMD, TSLA, AMZN, NFLX  
**US Equities — Other (CFDs):** JPM, BAC, WFC, GS, MS, V, MA, DIS, NKE, BA  
**ETFs (CFDs):** SPY, QQQ, VTI, IWM, XLE, XLV, XLK, XLF, XLI, XLU  
**Crypto (CFDs):** BTCUSD, ETHUSD (only these two)  
**Bonds/Commodities:** ZN, ZB, ZF, GC, SI  

---

## Position Sizing (Scoring Only)

Lot size depends SOLELY on scoring edge. No drawdown modifiers.

```
Edge = abs(LONG_score - SHORT_score)
Edge < instrument_threshold → NO TRADE
Edge threshold-25 → lot = base x 1.00
Edge 25-40 → lot = base x 1.50
Edge >40 → lot = base x 2.00

Lot base = 0.10 (forex) or proportional for commodities
Max cap = 1.00
```

### Anti-Loop (ALL instruments)
After an instrument appears in the top 3 scorers for 3+ consecutive rotations → DO NOT TRADE this instrument this rotation. Force evaluate alternatives.
Max 3 entries per symbol per direction per day.

### Thesis Decay
Each active thesis loses 5 bonus points per rotation. Rotation 4+ → bonus = 0.

---

## Risk Management

| Parameter | Value |
|-----------|-------|
| Max risk per position | 2% equity |
| CFD stop distance | 2-3% max |
| Stock stop distance | 1.5-3% |
| Max sector concentration | 33% per sector |
| Close window | 16:00-16:45 ART |
| No new entries | <30 min to 17:00 ART |

### Drawdown Rules
- Equity -5% intraday → reduce size 50%
- Equity -10% from peak → **HALT ALL TRADING**, log review
- NO revenge trading, NO averaging down

### Trailing Protocol (Manual via Python)
To adjust SL manually:
```
python -c "
import MetaTrader5 as mt5
mt5.initialize(path=r'E:\Darwinex MetaTrader 5\terminal64.exe')
mt5.login(3000102311)
ticket = TICKET_NUM
new_sl = NEW_SL
request = {
    'action': mt5.TRADE_ACTION_SLTP,
    'symbol': 'SYMBOL',
    'position': ticket,
    'sl': new_sl,
    'tp': CURRENT_TP,
    'comment': 'manual'
}
result = mt5.order_send(request)
print(result.retcode, result.comment)
mt5.shutdown()
"
```

Rules: BUY SL always BELOW entry, SELL SL always ABOVE.  
Never closer than 2-3 pips from current price (retcode 10016 = invalid stops).  
Retcode 10009 = OK.

Trailing logic:
- Entry → Stop at 2-3%
- +1% profit → Move stop to breakeven
- +3% profit → Trail at 1.5% behind
- +5% profit → Lock 2.5% minimum gain

---

### SHORT Trading Protocol

SHORT follows the same rules as LONG — same position sizing, no artificial limits.
SL/TP are dynamic based on ATR (same as LONG).

---

### Portfolio Correlation Check

Before opening a new position:
- Check if candidate correlates >0.70 with any open position
- If yes: reduce size by 50% or skip the trade
- If two open positions already correlate >0.70, do NOT open a third in the same sector
- Same sector = high correlation proxy if programmatic correlation unavailable

---

## Hard Rules (NEVER break)
- NO overnight holds — close by 16:45 ART
- Crypto CFDs: SL 5-8% due to volatility
- NO revenge trading after a loss
- NO averaging down on losing positions
- NO illiquid symbols (spread >100 pts = skip)
- EVERY position must have SL at entry

---

## News Sources

### Working RSS Feeds (use web_fetch, no curl/shell)

**PRIMARY — Google News RSS:**
- Top: `https://news.google.com/rss?hl=en-US&gl=US&ceid=US:en`

### Categories (10 categories, 20+ feeds)
Use Google News RSS format: `https://news.google.com/rss/search?q=QUERY&hl=en-US&gl=US&ceid=US:en`

**Geopolitics:** Iran US war, Israel Hezbollah, Russia Ukraine, China Taiwan, Trade war tariffs, Middle East attacks  
**Macro:** Fed FOMC, ECB rate, BOJ rate, CPI inflation, GDP recession, Employment NFP, Oil OPEC, Gold central bank  
**Tech/Semis:** NVDA earnings, Semiconductor AI, TSMC Taiwan, Apple product, Microsoft Azure  
**Crypto:** Bitcoin ETF, Crypto regulation SEC, Ethereum upgrade, Crypto exchange hack  
**Companies:** NVDA, AAPL, MSFT, GOOGL, AMZN, META, TSLA, AMD  
**Energy:** Oil price OPEC, Natural gas, Renewable energy  
**Commodities:** Silver price industrial, Copper China, Agricultural  
**Healthcare:** Pharma FDA, Healthcare stocks  
**Consumer:** Retail sales, Nike Adidas  
**General:** Tech stocks earnings, AI regulation, Tesla production

**Secondary (direct RSS):**
- BBC World: `https://feeds.bbci.co.uk/news/world/rss.xml`
- NYT World: `https://rss.nytimes.com/services/xml/rss/nyt/World.xml`
- Yahoo Finance: `https://finance.yahoo.com/rss/index.xml`

---

## Engram Topic Keys

```
scoring/rotation/{date}/{hour}/          ← All instruments evaluated
scoring/exit/{ticket}/                   ← Exit score time series
scoring/calibration/trade/{ticket}/      ← Score vs P&L real
scoring/calibration/summary/{symbol}/    ← Rolling stats
scoring/sectors/{date}/                  ← Price Momentum
scoring/news/{date}/{category}/          ← News impact
trading/{date}/trade/                    ← Every trade decision
trading/thesis/active                    ← Active thesis + decay
```

---

## Lessons Learned (Pre-v4.1, historical)
- SL on commodities: 3% minimum (XTIUSD stop-hunt history)
- Scoring >60 is the decision rule
- Iran deal already priced in → do not fade 20%+ complete moves
- Friday afternoon entries: high risk (<3h to close)
- Scoring = direction, not timing
- Full lesson history: Engram (mem_search "trading/lessons")
