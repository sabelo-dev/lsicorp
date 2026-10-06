---
title: Troubleshooting LSI Gold Digger
summary: Installer warnings, a closed simulated market, broker login and rejected trades.
audience: Users
order: 4
lastReviewed: 2026-10-06
status: published
---

## Windows says the publisher is unknown

The installer is not yet code-signed. Compare your download's SHA-256 checksum with the one on the release page. If they match, choose **More info**, then **Run anyway**. If they do not match, delete the file and download it again from the [Downloads page](/downloads).

## Nothing is moving on the chart

Without a broker the app uses simulated data, and the simulated market closes at weekends. Set **Settings > Simulated market hours** to 24/7.

## It will not log in to my broker

- Check that a MetaTrader 5 terminal is installed and that Python 3.10 or newer is available.
- Install the bridge packages: `python -m pip install -r bridge\requirements.txt`, run from the app's install folder.
- Enter the server name exactly as your broker gives it. If the terminal does not know the server, add the broker once in the terminal under **File > Open an Account**.
- If several terminals are installed, set the terminal path in Settings.

## Every trade is rejected

That is usually the risk engine doing its job. Open **Trading > Can it trade now?** to see each requirement with pass or fail. On a small account the broker's minimum position often exceeds the permitted risk.

## Orders are not being sent to the broker

The connection is read-only by default. See "Sending orders" in [Analysis, strategies and connecting MetaTrader 5](/docs/gold-digger/analysis-views).

## I found an installer somewhere else

Only install files listed on this website, and always compare the checksum.

## I need more help

See [Support](/support).
