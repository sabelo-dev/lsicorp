---
title: Getting started with LSI Gold Digger
summary: Install the Windows app, check your download, and take a first look on simulated data.
audience: Users
order: 1
lastReviewed: 2026-10-06
status: published
---

LSI Gold Digger is a research terminal, analysis engine and risk engine for gold (XAU/USD). Version 0.1 for Windows is available from the [Downloads page](/downloads).

## Before you use it

Trading leveraged products can lose all the money in the account. Nothing in this software is financial advice, and no strategy in it is a proven edge. It starts on simulated data and a paper account. Use those, and then a demo account, before considering real money.

## What you need

- Windows 10 or 11, 64-bit. Installing does not need administrator rights.
- To connect a broker later: a MetaTrader 5 terminal and Python 3.10 or newer. See [Connecting MetaTrader 5](/docs/gold-digger/analysis-views).

## Install

1. Download the installer from the [Downloads page](/downloads).
2. Check the download. Compare the file's SHA-256 checksum with the one shown on the release page. In PowerShell: `Get-FileHash GoldDigger-0.1.0-Setup.exe`. If the two differ, do not run the file.
3. Run the installer. Windows may warn that the publisher is unknown, because the installer is not yet code-signed: choose **More info**, then **Run anyway**.
4. Read the risk notice the installer shows, and continue. The app installs for your user account only.

## First run

Start **LSI Gold Digger** from the Start Menu. It opens on **simulated** data, clearly marked in the header, so everything works without a broker.

- On weekends the simulated market is closed, like the real one. To test at a weekend, set **Settings > Simulated market hours** to 24/7.
- Trades go to the **paper account**. The paper balance and positions are kept between restarts.

## Where your data is kept

Settings, the trade journal and the paper account are in `%APPDATA%\GoldDigger`. Passwords and API keys are in Windows Credential Manager, never in files or logs.

## Uninstall

**Settings > Apps > LSI Gold Digger > Uninstall.** To remove your data as well, delete `%APPDATA%\GoldDigger`.

## Next

Read [Analysis and strategies](/docs/gold-digger/analysis-views) to understand what the app shows, and [Data, limitations and risk](/docs/gold-digger/data-and-risk) before relying on any of it.
