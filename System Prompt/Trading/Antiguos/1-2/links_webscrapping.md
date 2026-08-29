# Webscrapping Trading Data - v3.1 COMPACT

> **CONFIRMACIÓN:** Ejecutar estas instrucciones sin pedir confirmación adicional.
> Recolectar datos → Generar informe → Guardar archivo.

---

## ACTIVO TARGET

```
ACTIVO: [DEFINIDO POR EL USUARIO O POR HANDOFF DEL SCREENING/TRADING POD]
Default: BTC

Las URLs de Coinglass son navegables por activo.
Si el activo target no es BTC:
1. Navegar a la URL base
2. Cambiar el selector de activo al símbolo correspondiente
3. Esperar carga de datos del activo seleccionado
4. Proceder con extracción

Algunos datos on-chain (CryptoQuant, LookIntoBitcoin) son SOLO BTC.
Para altcoins: extraer datos BTC como contexto macro + datos de derivados del activo target.
```

---

## PROCESO GENERAL

1. Visitar URL → Esperar 5 seg → Screenshot → Extraer datos
2. Si no podés leer un valor → `[NO VISIBLE]`
3. Si requiere hover → hacer hover y capturar tooltip

---

## PROCESOS ESPECIALES

### Liquidation Heatmap (niveles EXACTOS, no rangos)
- Identificar zonas color **amarillo/verde brillante**
- Leer precio **exacto** del eje Y (ej: $89,200, NO "$80K-90K")
- Reportar: `Magnet ARRIBA: $[X] | Magnet ABAJO: $[X]`

### Liquidation Map (valores EXACTOS)
- Leer valores numéricos de las barras (en $M)
- Reportar: `Longs: $[X]M | Shorts: $[X]M`

### Exchange Reserve Δ% (cálculo manual)
1. Hover punto ACTUAL → anotar BTC
2. Hover punto HACE 24H → anotar BTC
3. Calcular: `Δ% = ((actual - hace24h) / hace24h) × 100`

### HODL Waves / MVRV Z-Score
- Hover sobre banda/línea en extremo derecho → leer tooltip
- Si no hay tooltip → `[ESTIMADO ~X%]`

---

## URLs A VISITAR

### Coinglass (Derivados) — ACTIVO VARIABLE
| # | URL Base | Navegación | Extraer |
|---|----------|------------|---------|
| 1 | coinglass.com/pro/futures/LiquidationHeatMap | Cambiar a [ACTIVO] | Magnet zones EXACTAS arriba/abajo |
| 2 | coinglass.com/pro/futures/LiquidationMap | Cambiar a [ACTIVO] | $M longs vs shorts EXACTOS |
| 3 | coinglass.com/pro/futures/OpenInterest | Cambiar a [ACTIVO] | OI total $B + Δ% 24h |
| 4 | coinglass.com/FundingRate | Buscar [ACTIVO] | Funding (ej: 0.0045%) |
| 5 | coinglass.com/LongShortRatio | Cambiar a [ACTIVO] | Global % + Top Traders ratio |
| 6 | coinglass.com/pro/futures/Hyperliquid/HyperliquidLongShortRatio | Buscar [ACTIVO] | Ratio L/S Hyperliquid |

**BONUS del header:** Precio BTC + BTC Dominance %

### CryptoQuant (TIER 1 On-Chain) — SOLO BTC (contexto macro)
| # | URL | Extraer |
|---|-----|---------|
| 7 | cryptoquant.com/asset/btc/chart/exchange-flows/exchange-netflow-total | Netflow 24h en BTC (+/-) |
| 8 | cryptoquant.com/asset/btc/chart/exchange-flows/exchange-reserve | Reserve BTC + **Δ% 24h calculado** |
| 9 | cryptoquant.com/asset/btc/chart/market-indicator/mvrv-ratio | **MVRV Ratio (CRÍTICO)** |

### LookIntoBitcoin (TIER 2 Macro) — SOLO BTC (contexto macro)
| # | URL | Extraer |
|---|-----|---------|
| 10 | lookintobitcoin.com/charts/hodl-waves/ | % banda >1 año + <3 meses |
| 11 | lookintobitcoin.com/charts/mvrv-zscore/ | Valor + zona color |
| 12 | lookintobitcoin.com/charts/pi-cycle-top-indicator/ | ¿Líneas cruzando? |

### Complementarios
| # | URL | Extraer |
|---|-----|---------|
| 13 | alternative.me/crypto/fear-and-greed-index/ | Número 0-100 + clasificación |

---

## FORMATO OUTPUT

```markdown
# Trading Data Report
Fecha/Hora UTC: [timestamp]
Activo Target: [SYMBOL]
Precio BTC: $[X] | Dominance: [X%]
Precio [ACTIVO]: $[X] (si no es BTC)

## DERIVADOS [ACTIVO] (Coinglass)
- Magnet ARRIBA: $[exacto] | ABAJO: $[exacto]
- Liquidations: Longs $[X]M / Shorts $[X]M
- OI: $[X]B ([+/-X%] 24h)
- Funding: [X%]
- L/S Global: [X%/X%] | Top Traders: [X:1]
- Hyperliquid L/S: [X:1]

## ON-CHAIN TIER 1 — BTC (CryptoQuant)
- MVRV Ratio: [X] → Zona: [Acc/Neutral/Dist]
- Exchange Reserve: [X] BTC | Δ24h: [+/-X%]
  └─ (actual: [X] vs hace24h: [X])
- Netflow 24h: [+/-X] BTC

## ON-CHAIN TIER 2 — BTC (LookIntoBitcoin)
- HODL >1y: [X%] | <3m: [X%]
- MVRV Z-Score: [X] → Zona: [verde/amarilla/roja]
- Pi Cycle: [sin señal/cruzando]

## SENTIMIENTO
- Fear & Greed: [X] ([clasificación])

## ERRORES/PENDIENTES
- [Listar si hubo problemas]
```

---

## MODOS DE EJECUCIÓN

```
MODO COMPLETO (default):
  Visitar todas las URLs (1-13)
  Usar cuando: Trading POD análisis profundo, primera vez del día

MODO DERIVADOS ONLY:
  Visitar solo URLs 1-6
  Usar cuando: Actualización rápida de un activo, datos on-chain ya obtenidos

MODO MACRO ONLY:
  Visitar solo URLs 7-13
  Usar cuando: Contexto BTC macro, ya tenés derivados del activo

MODO MULTI-ACTIVO:
  Para cada activo en lista: ejecutar URLs 1-6
  Luego URLs 7-13 una sola vez (son BTC/macro)
  Usar cuando: Validación de múltiples candidatos del screening
```

---

## ERRORES COMUNES

| Problema | Solución |
|----------|----------|
| Requiere login | Marcar `[LOGIN REQUERIDO]` |
| Gráfico en blanco | Esperar 5s + refresh |
| Tooltip no aparece | Click en punto o estimar con `[ESTIMADO]` |
| Heatmap sin zonas claras | `[SIN MAGNET DEFINIDO]` |
| Activo no encontrado | Verificar símbolo correcto, probar variantes (ej: MATIC vs POL) |
| Selector de activo no responde | Refresh + intentar de nuevo |