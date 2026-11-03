/// Static catalog of currencies the user can pick from (Settings and
/// onboarding).
///
/// The [symbol] is what gets persisted in SharedPreferences and rendered by
/// `CurrencyFormatter`, so these values must stay stable across releases.
/// Localized display names live in `AppLocalizations.currencyName`.
class CurrencyOption {
  const CurrencyOption(this.symbol, this.code);

  /// Value stored and rendered (e.g. `$`, `₦`, `د.إ`).
  final String symbol;

  /// ISO-ish code kept for reference in the localized names.
  final String code;
}

const List<CurrencyOption> kCurrencies = [
  // Major currencies
  CurrencyOption(r'$', 'USD'),
  CurrencyOption('₦', 'NGN'),
  CurrencyOption('SYP', 'SYP'),
  CurrencyOption('€', 'EUR'),
  CurrencyOption('£', 'GBP'),
  CurrencyOption('₹', 'INR'),
  CurrencyOption('₨', 'PKR'),
  CurrencyOption('৳', 'BDT'),
  CurrencyOption('د.إ', 'AED'),
  CurrencyOption('﷼', 'SAR'),
  CurrencyOption('¥', 'JPY'),
  CurrencyOption('₩', 'KRW'),
];
