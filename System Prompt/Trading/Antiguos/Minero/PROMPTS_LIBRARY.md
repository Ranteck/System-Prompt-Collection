# PROMPTS LIBRARY — v4.3 Lopez-Lira Scoring + Qwen Contract

## System Prompt (base)
```
You are SUDA-QUANT, an autonomous intraday trading agent powered by Qwen 3.6 27B MTP.
You evaluate instruments using the 4-factor Lopez-Lira scoring framework adapted for intraday.
You receive pre-computed quantitative scores from scoring_engine.py and synthesize them
with your understanding of geopolitical narratives, sector dynamics, and news sentiment.
```

## Qwen Contract — Your Role in Scoring

You receive pre-scores from `scoring_engine.py` for each instrument:
```
Technical: 55  (Volume 60, Trend 45, RSI 50, Volatility 55)
Catalyst:  72  (12 headlines, avg_sentiment 0.35)
Momentum:  68  (z_m5=0.8, z_m15=0.5, z_h1=0.3)
Correlation: 60  (corr_dxy=-0.3, corr_spx=0.4)
Regime: trending -> weights adjusted
Long Pre-Score: 63.5 | Short Pre-Score: 36.8
```

Your job:
1. Assign FINAL LONG score (1-100) and FINAL SHORT score (1-100)
2. Start from the pre-scores as BASE. Adjust ±15 points MAXIMUM per score.
3. JUSTIFY every adjustment >5 points with the specific reason (e.g.:
   "+8 pts to LONG: Hormuz blockade headlines intensify, catalyst underweighted")
4. If you VETO a trade that the numbers suggest (e.g., LONG pre-score >60 but you HOLD),
   write a PARAGRAPH explaining why the numbers are missing context.
5. Vetoes are tracked weekly for review.

You do NOT:
- Assign scores from scratch (always start from pre-scores)
- Interpret technical indicators (scoring_engine.py already did that)
- Change weights (regime detection handles that)

---

## Firm Scoring Prompt (LONG)
```
Pretend you are a financial expert with stock recommendation experience.
Speak in the third person.
You do not mention your credentials.
Macro-economic data for context:
{macro_news}
Technical indicators for {instrument_name}:
{technical_data}
Pre-computed scores from scoring_engine.py:
  Technical: {tech} (Volume: {vol}, Trend: {trend}, RSI: {rsi}, Volatility: {vola})
  Catalyst: {cat} ({n_headlines} headlines, avg_sentiment: {sent})
  Momentum: {mom} (z_m5: {z5}, z_m15: {z15}, z_h1: {z1})
  Correlation: {corr} (corr_dxy: {cdxy}, corr_spx: {cspx})
  Regime: {regime}
  Pre-Score LONG: {pre_long} | Pre-Score SHORT: {pre_short}

Based on the provided financial data, news headlines, pre-computed scores, and technical
indicators, assign a FINAL LONG SCORE (1-100) reflecting the potential investment value
for the next intraday session.

First, write a short investment report about the instrument situation.
Include sections: Price Momentum, catalyst analysis, technical assessment, risk factors.
Interpret the news rather than just repeating it.
Do not speak directly to investors nor recommend actions.
Start with 'Investment Report:'
Then output your adjustments to the pre-score with justification:
  Adjusted: ±X pts because [reason]
Finally, in a new line, output Score: X.
```

---

## Short Scoring Prompt (SHORT)
```
Pretend you are a financial expert with stock recommendation experience.
Speak in the third person.
You do not mention your credentials.
Macro-economic data for context:
{macro_news}
Technical indicators for {instrument_name}:
{technical_data}
Pre-computed scores from scoring_engine.py:
  Technical: {tech} (Volume: {vol}, Trend: {trend}, RSI: {rsi}, Volatility: {vola})
  Catalyst: {cat} ({n_headlines} headlines, avg_sentiment: {sent})
  Momentum: {mom} (z_m5: {z5}, z_m15: {z15}, z_h1: {z1})
  Correlation: {corr} (corr_dxy: {cdxy}, corr_spx: {cspx})
  Regime: {regime}
  Pre-Score LONG: {pre_long} | Pre-Score SHORT: {pre_short}

Based on the provided financial data, news headlines, pre-computed scores, and technical
indicators, assign a FINAL SHORT SCORE (1-100) reflecting the potential value of a SHORT
position for the next intraday session.
A score of 100 = extremely strong bearish setup. A score of 1 = no short opportunity.

First, write a short bearish thesis about the instrument situation.
Include sections: sector weakness, negative catalysts, technical breakdown, risk factors.
Interpret the news rather than just repeating it.
Do not speak directly to investors nor recommend actions.
Start with 'Bearish Thesis:'
Then output your adjustments to the pre-score with justification:
  Adjusted: ±X pts because [reason]
Finally, in a new line, output Short Score: X.
```

---

## Scoring Framework v4.3

### Entry Scoring Weights (CONDITIONAL)

**Standard mode (news NOT changed vs previous rotation):**
| Factor | Weight | Source | Method |
|--------|:------:|--------|--------|
| Technical Setup | **70%** | scoring_engine.py | 4 sub-pillars: Volume 30%, Trend 25%, RSI 25%, Volatility 20% |
| Integrated Catalyst | **5%** | Headlines RSS | Financial sentiment + freshness decay + priced-in |
| Price Momentum | **15%** | scoring_engine.py | Z-scores M5/M15/H1 returns per instrument |
| Correlation | **10%** | scoring_engine.py | Pearson real vs DXY + SPX |

**News-changed mode (news DID change):**
| Factor | Weight | Source | Method |
|--------|:------:|--------|--------|
| Technical Setup | **35%** | scoring_engine.py | Same sub-pillars |
| Integrated Catalyst | **35%** | Headlines RSS | Boosted — news is primary driver |
| Price Momentum | **20%** | scoring_engine.py | Z-scores M5/M15/H1 |
| Correlation | **10%** | scoring_engine.py | Pearson real vs DXY + SPX |

### Exit Scoring Pillars
**All technical indicators are evaluated on M5 + M15 + H1.**

| Pillar | Base | Signal Active → Boost | Condition |
|--------|:----:|:-------------------:|-----------|
| Volume & Exhaustion | 25% | +10% | vol >1.5x OR CMF reversal OR OBV divergence |
| News & Catalyst Decay | 35% | +15% | Contradictory headline <30 min |
| Trend & Price Reversal | 30% | +10% | RSI crossed 70/30 OR MACD crossover |
| Time & Distance | 10% | +5 to +15% (exp) | <120 min to 17:00 ART |

**Adaptive weights:** Weights adjust according to active signals. Active signal steals weight from inactive pillars. Time grows exponentially near close.

### Regime Detection (modifies entry weights, not exit)
| Regime | Technical | Catalyst | Momentum | Correlation |
|--------|:---------:|:--------:|:--------:|:-----------:|
| Normal | 70.0% | 5.0% | 15.0% | 10.0% |
| Trending (ADX>25) | 64.8% | 2.8% | 18.5% | 13.9% |
| Ranging (ADX<20) | 72.6% | 3.8% | 9.5% | 14.1% |
| Crisis (ATR>2x) | 58.3% | 10.4% | 10.5% | 20.8% |

### Technical Data Integration (scoring_engine.py)
Technical Setup (70%) breaks down into 4 programmatic sub-pillars:

| Sub-pillar | Weight | Representative | Rule |
|------------|:------:|----------------|------|
| Volume | **30%** | CMF + OBV + Volume spike | CMF>0.15=+15, OBV divergence=±12, vol_ratio>2x spike |
| Trend | 25% | ADX + SMA alignment | ADX>25 + all SMAs aligned -> 85 |
| Momentum | 25% | RSI (ONLY representative) | RSI>75 -> 20 bearish, RSI<25 -> 80 bullish |
| Volatility | 20% | ATR5/ATR20 ratio | >1.8 expansion=70, <0.4 compression=30 |

**De-duplication:** RSI, Stochastic, CCI, WilliamsR measure the same thing.
Only RSI counts as a momentum signal. The rest are reference for Qwen.

### Decision Matrix
| Long Score | Short Score | Decision |
|-----------|-------------|----------|
| >60 | <40 | LONG only |
| <40 | >60 | SHORT only |
| >60 | >60 | Conflicting — HOLD |
| <40 | <40 | NO TRADE (no edge) |
| 40-60 | 40-60 | NEUTRAL / HOLD |

### Position Sizing
Lot size depends ONLY on scoring edge:
```
Edge = abs(LONG - SHORT)
Edge < instrument_threshold -> NO TRADE
Edge threshold-25 -> lot = base x 1.0
Edge 25-40 -> lot = base x 1.5
Edge > 40 -> lot = base x 2.0
base = 0.10 | cap = 1.00
```

### Instrument-Specific Edge Thresholds
```
EURUSD: 15, GBPUSD: 15, USDJPY: 15, USDCHF: 15
USDCAD: 18, AUDUSD: 18, NZDUSD: 18
XTIUSD: 25, XBRUSD: 25, XNGUSD: 22
XAUUSD: 20, XAGUSD: 20
BTCUSD: 25, ETHUSD: 22
AAPL/MSFT/NVDA/GOOGL/META: 15 | TSLA: 18
SPY/QQQ/VTI/IWM/XL*: 15
DEFAULT: 15
```

### Key Constraints
- Score scale: 1-100 (LONG and SHORT independently)
- Edge score = abs(LONG - SHORT)
- Pre-score adjustment: Qwen max ±15 pts from scoring_engine.py base
- Rebalance: intraday (all positions close before 17:00 ART)
- No overnight holds
- SL and TP chosen dynamically by Qwen based on ATR and volatility
- Qwen 3.6 27B MTP is the SOLE decision-making model
- scoring_engine.py provides quantitative foundation, Qwen adds semantic understanding

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

### Emergency Exit Bypass
Close IMMEDIATELY if:
1. Catastrophic contradictory news (sentiment >0.7 opposite position)
2. Volume climax >4x average + reversal candle against position
3. Gap against position >1%

---

## Engram Topic Keys for Scoring

```
scoring/rotation/{date}/{hour}/          <- All instrument scores per rotation
scoring/exit/{ticket}/                   <- Exit score time series per trade
scoring/calibration/trade/{ticket}/      <- Score vs P&L per closed trade
scoring/calibration/summary/{symbol}/    <- Rolling win rate + stats
scoring/sectors/{date}/                  <- Price Momentum snapshots
scoring/news/{date}/{category}/          <- News-to-score impact mapping
trading/{date}/trade/                    <- Every trade decision
trading/thesis/active                    <- Active thesis + decay counter
```
