# Estrategia de Trading — Tipos de Posición

Instrumentos tácticos: **Liquidity Mining (LM) pools**, **grid bots de futuros** y,
como complemento opcional, **posición direccional en perpetuos** (no como práctica de
trading activo, sino como otra forma de expresar una jugada puntual). Cuarto
instrumento, no táctico: **Spot / Acumulación a Largo Plazo (Holding)**, como posición
core con horizonte de meses a años.

---

## Señales de descubrimiento

Una **señal de descubrimiento** es cualquier cosa que hace que un activo merezca
análisis. Sirve para *encontrar* candidatos — **no es un gatillo de entrada.**

Ejemplos:

- **APR muy alto** en un pool LM → indica interés/volatilidad sobre el token.
- **Noticias / catalizadores** → un evento que puede mover el precio.
- **Niveles técnicos** → soporte/resistencia tocado, sobreventa extrema, ruptura.

> **Principio:** la señal abre la investigación, no la posición. APR inflado, una
> noticia o un soporte tocado son razones para *mirar* un activo. La decisión de
> entrar viene **después** del análisis (rango, fundamentales, riesgo, timing).
> ⚠️ Un APR inflado puede ser trampa para retail.

---

## Liquidity Mining

Funciona como spot con apalancamiento (hasta 10x) mientras genera APR.
Rinde bien en mercado neutral o alcista.

**Estrategia largo plazo:** criptos top-10 o proyectos con fundamentales sólidos.

**Estrategia especulativa:** tokens riesgosos con APR muy alto. El APR alto funciona
como señal de descubrimiento (ver sección arriba), no como gatillo automático.

Dada la señal, hay dos formas de expresar la jugada:

- **Abrir el pool LM nuevo:** capturar la suba inicial y luego decidir entre
  *mantener* (si el precio se alejó del rango de liquidación, el APR compensa la
  espera) o *cerrar y tomar ganancias*.
- **Abrir una posición menor en futuros perpetuos:** en vez de abrir el pool,
  expresar la jugada con un perp de menor capital (ver sección Perp).
**Sizing:** mínimo 50 USDT, luego en cifras redondas (100, 120, 150...) para
facilitar el tracking.

### Opciones de salida (LM)

| Opción | Cuándo usarla |
| -------- | --------------- |
| Cerrar y recuperar USDT | Asumir la pérdida, salir del activo |
| Cerrar y recuperar el token | El token tiene potencial; esperar a que recupere precio |
| No cerrar + agregar 50 USD | Bajar precio de liquidación, ganar tiempo |
| No cerrar + agregar capital suficiente | Reducir el apalancamiento a un nivel seguro |

---

## Grid Bot (futuros)

### Modo de operación preferido

**Neutral por defecto.** La incertidumbre direccional tiene costo psicológico real;
la posición neutral lo elimina y deja que el bot capture el rango sin apostar a
dónde va el precio.

**Excepción:** abrir bot direccional (long/short) solo cuando la tendencia sea
suficientemente clara para justificar el riesgo — ej: caída sostenida de mercado,
ruptura evidente de soporte/resistencia.

### Apalancamiento

Rango habitual **x5–x10**, preferencia por el mínimo que permita grids rentables.
Mayor apalancamiento = mayor exposición en movimientos bruscos.

### Filosofía de ejecución

**Muchas operaciones pequeñas > pocas operaciones grandes.** Un bot de alta
frecuencia y bajo retorno por grid es preferible a uno que busca el retorno máximo
por operación: si una operación grande sale mal, implica esperar el siguiente ciclo
para recuperar; con operaciones pequeñas el drawdown es menor y la recuperación más rápida.

### Criterios de apertura

No se elige el rango manualmente. Flujo:

1. Identificar una cripto potencial vía señal de descubrimiento (APR alto, noticia,
   nivel técnico) o pedir exploración de posiciones posibles.
2. Definir rango y grids sobre el activo elegido.

### Grid direccional (long / short)

El direccional captura grid profit en las oscilaciones **mientras** el precio se
mueve en la dirección apostada. Ganás por dos lados: fees + movimiento direccional.
Pero tiene dos costos que el neutral no tiene.

**1. El timing dentro del trend importa.** "Tendencia clara" no alcanza — el punto
de entrada decide el resultado:

- **No shortear en el wick de una caída extrema.** Tras un -30/-40% con vela de
  rechazo, lo probable es un rebote primero. Entrar short ahí te genera pérdida
  mientras el precio sube antes de que el trend retome. Esperar el rebote a la
  resistencia para entrar.
- **No entrar long en el techo.** El long grid se abre cerca del piso, no después
  de que el precio ya subió.
**2. Perdés la salida limpia del neutral.** Este es el punto central:

> El grid **neutral** te regala la decisión de salida: el precio sale del rango =
> cerrar. Es inequívoco.
>
> El grid **direccional** no tiene esa señal. ¿Cuándo termina un long grid? No hay
> un "rango roto" que te diga *salí*. Por eso el direccional exige **definir la
> regla de salida protectora antes de abrir** — trailing stop o nivel de precio
> protector fijo — nunca improvisarla. Un nivel objetivo favorable puede complementar
> esa protección, pero nunca sustituirla ni definir el presupuesto de riesgo. Si no
> podés definir de antemano cuándo salís ante un movimiento adverso, el neutral es la
> opción más segura.

---

### Criterios de cierre

> **Principio central:** en un grid neutral, el *grid profit* (fee capture) es el
> retorno; el PnL direccional es el riesgo. Un drawdown **dentro del rango** es
> ruido reversible — el mecanismo de la estrategia está diseñado para recuperarlo —
> y **NO es motivo de cierre**. El motivo de cierre es que el **precio salga del
> rango** (tesis de lateralización rota → no revierte → camino a liquidación).
>
> El discriminador correcto entre "revierte" y "no revierte" es **dónde está el
> precio respecto del rango**, no un % de PnL.

**Por qué el -15% NO sirve como SL en bot neutral:**
A 10x, -15% de PnL ≈ apenas **1.5% de movimiento de precio** = ruido de mercado.
Cerrar ahí convierte un mark-to-market temporal en pérdida permanente, además de
matar el grid profit acumulado y resetear todo (muerte por mil cortes).

**Las herramientas difieren por exchange:**

| Exchange | TP/SL disponible | Cómo configurar |
|----------|------------------|-----------------|
| **Bybit** | Solo **PnL%** (no hay nivel de precio) | SL como *guardrail de liquidación*, ancho (~-40/-60% PnL). Traducir "precio toca piso del rango" a PnL% según leverage. Sin TP apretado en bots neutrales. |
| **BingX** | **Nivel de precio** + Trailing up/down + Trailing Stop | SL por precio justo debajo del piso del rango (ejemplo ilustrativo: rango $X–$Y → stop apenas debajo de $X, fuera del ruido intradiario). Trailing up/down opcional para seguir tendencia suave sin cerrar el grid. |

**Regla de salida según tesis del bot:**

- **Bot neutral** → SL por precio fuera de rango (BingX) o PnL ancho como guardrail
  (Bybit). **Sin TP apretado.** Opcional en BingX: Trailing up/down.
- **Bot direccional** → **Trailing Stop** (BingX). Acá sí apostaste al momentum y
  querés capturar lo máximo posible — el trailing es la herramienta correcta para
  *este* caso, no para el neutral. Un nivel objetivo favorable es solo
  complementario: nunca es protección adversa ni puede usarse para calcular o limitar
  el presupuesto de riesgo.

> Referencia de magnitudes a 10x: -15% PnL ≈ 1.5% precio (ruido) · liquidación
> ≈ -100% PnL ≈ ~10% precio. El SL útil vive cerca del borde del rango, no del wiggle.

---

## Perp / Posición direccional

No es trading activo. Es **otra opción para expresar una jugada direccional puntual**
cuando no querés abrir un pool LM completo ni un grid. Útil cuando tenés una tesis
de corto plazo (un rebote, una continuación de caída) y querés exposición acotada
con salida limpia.

**Setup básico:**

- **Entrada:** market o límite en la zona definida por la señal técnica.
- **Stop Loss:** por nivel de precio (justo debajo del piso/soporte relevante).
- **Take Profit:** parcial. Salir la mitad en el primer objetivo, dejar correr el resto.

### Principio clave — leverage según distancia al stop

El apalancamiento se **calibra a la distancia al stop**, no se elige primero.

Si el stop está a **X%** de distancia en precio, a un leverage **L** la pérdida al
stop es **X% × L** del capital. Cuando X% × L se acerca a 100%, la **liquidación
dispara antes que tu stop** y perdés el control de la salida.

> **Regla:** mantené `X% × L` cómodamente por debajo de ~60-70% para que el stop
> ejecute limpio antes de cualquier riesgo de liquidación. Un stop ajustado tolera
> leverage alto; un stop ancho exige bajarlo. Cada caso se analiza — esto es guía,
> no fórmula.

### Perp vs Grid direccional

| Tesis | Instrumento |
|-------|-------------|
| Movimiento direccional de **corto plazo**, querés salida limpia | **Perp** |
| Querés capturar fees mientras el precio se mueve en tu dirección **con oscilaciones** (horizonte más largo) | **Grid direccional** |

El grid direccional tiene dos variantes según la dirección apostada: **long** (esperás
suba) o **short** (esperás caída). Cuanto más largo el horizonte y más vaivenes en el
camino, más sentido tiene el grid sobre el perp.

El perp captura solo el movimiento direccional, sin fee capture, pero con control
total. El grid direccional suma fees pero te cobra la salida (ver sección Grid
direccional). Para horizontes cortos el perp gana: el grid no tiene tiempo de
generar fees que importen.

---

## Spot / Acumulación a Largo Plazo (Holding)

No es una jugada táctica como LM, Grid o Perp. Es una **posición core de largo
plazo**, con horizonte de meses a años, destinada a acumular activos de alta
calidad sin depender del resultado de una operación puntual. Se financia con
ganancias realizadas o con capital asignado explícitamente para holding, y se
trackea por separado del capital de los instrumentos tácticos.

### Universo de tokens

El punto de partida es **BTC, ETH, BNB, SOL, ADA, XRP, XLM, LINK, DOT, AVAX y
LTC**. Es un conjunto concreto pero vivo: apunta aproximadamente al top 15-20 por
capitalización, excluyendo stablecoins, activos wrapped/pegged y tokens de categoría
meme. No es una lista exhaustiva ni permanente; se revisa cuando los rankings de
market cap cambian de forma relevante para incorporar o quitar activos según su
calidad y posición.

### Señal de entrada

El timing usa como contexto de **macrociclo / régimen** las señales on-chain solo BTC
de la Capa 1 de `trading_pod_v1.2.md`: **LTH Supply, LTH Net Position Change,
LTH-SOPR y HODL Waves**. Indican si el mercado amplio está en acumulación o
distribución y ese contexto se aplica a todo el universo de holding; **no validan la
salud fundamental de cada token**. La calidad por token se aproxima mediante su
permanencia en el top-N por market cap y la ausencia de una tesis fundamental rota,
según la Política de salida. Se busca comprar debilidad o agotamiento dentro de una
tesis todavía intacta, no perseguir fortaleza después de una suba.

Son las mismas métricas LTH/HODL ya definidas para BTC en la Capa 1 del Trading POD,
reutilizadas aquí en vez de reinventadas. Obtenerlas exige consultar específicamente
los datos BTC de esa capa — ya disponibles cuando hay un análisis profundo de BTC
activo —; no son datos que el escaneo rutinario del universo del Screening POD
provea sin una consulta adicional. Este chequeo **no abre un camino por candidato a
través de las Capas 1-4**, y no se agregan detectores nuevos.

### Sizing y cadencia

Usar DCA en tramos chicos y fijos: **mínimo 50 USDT, luego cifras redondas**
(100, 120, 150...), consistente con el sizing de LM. La cadencia regular construye
la base; cuando se activa una condición de entrada puede sumarse un tramo extra
oportunista. Es un enfoque híbrido — DCA regular más refuerzo oportunista —, no un
calendario único y rígido.

Como defaults ajustables, el capital de holding se limita al **25% del capital total
gestionado** y ningún token individual puede superar el **40% del capital de
holding**. Si un token rebasa ese 40%, se evalúa rebalancear mediante toma parcial de
ganancias o redirigir los nuevos tramos de DCA al resto del universo. Son referencias
de partida, no absolutos rígidos; deben revisarse con la composición y el riesgo del
portfolio.

### Política de salida

Es holding, no trade: **no tiene take-profit rutinario**. Solo se reduce o cierra un
token por rebalanceo del portfolio, necesidad de capital en otro destino, o pérdida
de calidad/posición top-N acompañada por una tesis fundamental rota — por ejemplo,
riesgo de delisting o deterioro fundamental.

> La volatilidad normal no invalida el holding. Así como el drawdown dentro del
> rango no es motivo de cierre para un Grid neutral, una oscilación ordinaria no
> justifica abandonar una tesis fundamental intacta.

### Ejecución y orquestación

La compra se ejecuta **manualmente en BingX spot**, mediante Chrome o la tool
`bingx-ai-skills:spot-trade`. Nunca se ejecuta mediante `order-executor/`, que es
perp-only; se mantiene el mismo límite de ejecución manual que ya rige para los grid
bots.

Integrar este chequeo de portfolio y baja frecuencia en una sesión real de
`/trading-start` es un trabajo futuro separado. Esta sección documenta únicamente
la estrategia; no modifica la orquestación ni la ejecución actual.

---

## Operar en bear market

El resto del documento asume mercado **neutral o alcista**. En un downtrend
sostenido (caída multi-día con drivers macro persistentes) las reglas cambian:

- **LM:** sufre. Impermanent loss + leverage = el buffer de liquidación se come
  rápido. El APR alto no compensa una caída sostenida del activo subyacente.
  **Evitar abrir pools nuevos**; monitorear los abiertos de cerca.
- **Grid neutral:** si el rango se rompe por abajo → salir (la regla de siempre).
  **No promediar hacia abajo** esperando una reversión que el mercado no confirma.
- **Grid direccional / perp:** si operás, **alineado al trend** (short) y con timing
  — esperar el rebote a la resistencia para entrar, no shortear el wick.
- **Spot / Acumulación:** un downtrend sostenido es precisamente el contexto de
  “comprar debilidad” para el que existe este instrumento. El DCA regular continúa y
  el tramo oportunista puede reforzarse con más convicción si la tesis fundamental
  del token específico sigue intacta. Si la causa del drawdown pone esa tesis en
  duda — no solo por miedo general de mercado — prevalece **Default: preservar
  capital**.
- **Default: preservar capital.** Muchas veces la mejor jugada es no abrir nada
  nuevo hasta una señal de estabilización (ej: vela diaria verde con volumen, flujos
  de ETF que dejan de ser negativos, resolución de catalizador macro).

> En downtrend sostenido, preservar capital es una posición. Perderse una operación
> cuesta cero; quedar atrapado en la próxima pierna abajo cuesta capital real.
