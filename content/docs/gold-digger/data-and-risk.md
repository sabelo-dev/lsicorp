---
title: Data, limitations and risk
summary: Where the data comes from, what the risk engine enforces, and what this version cannot do.
audience: Users
order: 3
lastReviewed: 2026-10-08
status: published
---

## Data sources

- **Prices.** Live quotes and closed bars from your MetaTrader 5 terminal, with broker time converted to UTC. Without a broker, a simulator supplies data that is clearly marked as simulated.
- **Macro.** Economic series from FRED, using your own free API key.
- **News.** RSS feeds, scored by keyword rules. Every item keeps its source, time and link.
- **Calendar.** A weekly economic calendar from a public export, cached on your PC.

Orders are refused if the latest price is more than 10 seconds old.

## What the risk engine enforces

Every order is checked at the moment of execution, even after you have approved it.

- A stop loss is mandatory, and reward-to-risk must be at least 1:2.
- One position at a time. No averaging into a losing position.
- Daily loss under 2% and weekly loss under 5% by default.
- No trading within 30 minutes of a high-impact US event, in abnormal volatility, or on a wide spread.
- Position size is calculated from the account's equity and the stop distance, and is always rounded down.
- After losses, drawdown tiers reduce the risk per trade, and trading is suspended below 80% of the reference balance. Risk never increases after a loss.

**Hard ceilings** that no setting can exceed: 2% per trade, 5% daily, 10% weekly and three positions. Martingale, grid recovery and averaging down are blocked.

## Small accounts

Whether a small balance can trade gold is decided by the broker's smallest position. On a standard contract a small account cannot fit even the minimum trade inside the limits, so the risk engine rejects almost every setup. That is correct behaviour. **Trading > Can it trade now?** shows what the broker's contract needs.

A small-account mode exists and is off by default. It needs a typed confirmation, raises the limits for the minimum position only, and makes a suspension much more likely.

**Backtesting** can simulate an account you describe (deposit, contract size, minimum lot, leverage, spread and the risk rules) and, with **Account fit** ticked, shows how each strategy would have ended over many separate periods. Run it again when the balance changes materially.

## Daily profit target

An optional stopping rule under **Settings > Daily profit target**. When the day's realised gain reaches the target, new entries pause and the app asks whether to keep trading; with no answer it stops until the next day. Open positions keep their stop loss and targets. It cannot make a day reach the target, and it never changes a risk limit.

## Limitations of version 0.3

- The strategies are explainable starting points, not a proven edge. Validation on real broker history is not complete.
- Backtests are technical-only: macro and news are not included.
- The calendar source is unofficial and may be missing values.
- News sentiment is keyword-based: transparent, but coarse.
- The simulator replays the same price path on each launch.

## Before any real money

1. Run backtests and walk-forward tests on your own broker's history.
2. Paper-trade for weeks and review the journal.
3. Move to a demo account, and only after that consider a live one.

## No guarantee

Market outcomes are uncertain. Nothing in LSI Gold Digger is financial advice, and nothing in it guarantees a return.
