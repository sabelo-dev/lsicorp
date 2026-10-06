---
title: Analysis, strategies and connecting MetaTrader 5
summary: What each view shows, how the four strategies decide, and how to connect a broker safely.
audience: Users
order: 2
lastReviewed: 2026-10-06
status: published
---

Every view explains itself: scores come with their reasons, and no AI model produces or edits a score.

## Analysis views

- **Technical.** Moving averages, RSI, MACD, ATR, Bollinger Bands and ADX across 15-minute, 1-hour, 4-hour, daily and weekly bars. No value depends on future bars.
- **Market structure.** Confirmed swing highs and lows, trend, breaks of structure, failed breakouts and clustered support and resistance.
- **Regime.** A label from strongly bullish to strongly bearish, with high-volatility and event-risk overlays.
- **Macro.** A rule-based score from real yields, the dollar, breakevens, Fed funds and unemployment, with the reason for every point. Needs a free FRED API key.
- **News and calendar.** Gold-relevant headlines with source and sentiment, and the week's economic events. High-impact US events trigger a trading blackout.
- **Weekly Focus.** A weekly thesis: bias, levels, bullish and bearish scenarios, what would invalidate each, and the events to watch.

Chart overlays for Double Bollinger Bands, the regression channel, structure labels and liquidity pools are switched on from the Market page.

## Strategies

Four strategies share the same risk engine and backtester. Choose one under **Settings > Strategy**.

- **Trend pullback** (the default). Trades with the higher-timeframe trend after a pullback, on a 15-minute break of structure.
- **Confluence.** Scores regression, Double Bollinger Bands, market structure, liquidity, macro and daily bias from 0 to 100, and needs a high score with agreement between engines.
- **Ensemble.** Seven independent modules combined by a transparent weighted score. Any failed gate gives no trade.
- **Adaptive.** Evolves its own rules from recent market behaviour and retires them when they stop working. It often has nothing to trade; that is by design.

Each outputs **BUY**, **SELL** or **WAIT**, with every condition and risk listed. Ensemble and Adaptive are limited to paper and demo accounts until an operator promotes one with a typed confirmation.

Compare them on the same history under **Backtesting > Compare strategies**.

## Connecting MetaTrader 5

Use a **demo** account first.

1. Install a MetaTrader 5 terminal, from your broker or the generic one.
2. Install the bridge's Python packages. Open a Command Prompt in the app's install folder and run `python -m pip install -r bridge\requirements.txt`.
3. In the app, open **Settings > MT5 account login**. Enter the account number, the server name exactly as your broker gives it, and the password, then choose **Log in**.

The gold symbol is found automatically. Your password is stored in Windows Credential Manager and is passed only to the bridge and the terminal on your own PC.

## Sending orders

The connection is **read-only by default**. An order is only sent when all of these are true:

1. **Bridge order commands** is enabled in Settings.
2. **MT5** is selected as the execution venue.
3. For a live account, live trading has been unlocked with a typed confirmation in this session.
4. The risk engine approves the order at the moment of execution.

Automatic trading is always off after a restart and switches itself off on stale data, a lost connection, the emergency stop or a drawdown suspension.
