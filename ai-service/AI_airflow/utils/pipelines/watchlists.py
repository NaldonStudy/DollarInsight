"""대상 종목/ETF/지수 리스트 정의."""

US_STOCKS: list[str] = [
    "AAPL", "MSFT", "GOOGL", "AMZN", "META", "NVDA", "AMD", "INTC",
    "TSM", "ASML", "ADBE", "ORCL",
    "CPNG", "BABA",
    "TSLA", "BA", "DAL", "UBER", "FDX",
    "WMT", "COST",
    "JPM", "BAC", "GS", "V", "MA", "PYPL", "AIG", "SPY",
    "KO", "PEP", "MCD", "SBUX", "NKE",
    "NFLX", "DIS", "SONY",
]

METRIC_STOCKS: list[str] = [ticker for ticker in US_STOCKS if ticker != "SPY"]


US_ETFS: list[str] = [
    "VOO", "SPY", "VTI",
    "QQQ", "QQQM", "TQQQ",
    "SCHD",
    "SOXX", "SMH",
    "ITA",
    "XLF", "XLY", "XLP",
    "ICLN",
]


US_INDICES: dict[str, dict[str, str]] = {
    ".SPX": {"name": "S&P 500", "market": "N", "yf_symbol": "^GSPC"},
    ".IXIC": {"name": "NASDAQ Composite", "market": "N", "yf_symbol": "^IXIC"},
    ".DJI": {"name": "Dow Jones Industrial Average", "market": "N", "yf_symbol": "^DJI"},
    ".SOX": {"name": "PHLX Semiconductor", "market": "N", "yf_symbol": "^SOX"},
    ".VIX": {"name": "CBOE Volatility Index", "market": "N", "yf_symbol": "^VIX"},
    ".RUT": {"name": "Russell 2000", "market": "N", "yf_symbol": "^RUT"},
}


FRED_DAILY_SERIES: dict[str, dict[str, str]] = {
    "DGS10": {"name": "10-Year Treasury Constant Maturity Rate", "unit": "Percent"},
    "DGS2": {"name": "2-Year Treasury Constant Maturity Rate", "unit": "Percent"},
    "VIXCLS": {"name": "CBOE Volatility Index", "unit": "Index"},
    "DEXUSEU": {"name": "U.S. / Euro Foreign Exchange Rate", "unit": "USD/EUR"},
    "DEXCHUS": {"name": "China / U.S. Foreign Exchange Rate", "unit": "CNY/USD"},
    "DCOILWTICO": {"name": "Crude Oil Prices: WTI", "unit": "Dollars per Barrel"},
}


__all__ = [
    "US_STOCKS",
    "US_ETFS",
    "US_INDICES",
    "FRED_DAILY_SERIES",
    "METRIC_STOCKS",
]


