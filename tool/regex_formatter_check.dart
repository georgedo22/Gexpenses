// Simulates FilteringTextInputFormatter.allow (which uses pattern.allMatches
// and bans every region between/outside matches — see Flutter's
// text_formatter.dart) for the old (anchored + double-backslash) and fixed
// patterns used in this project.
void main() {
  final brokenAnchored = RegExp(r'^\d*\.?\d{0,2}'); // with '^' anchor
  final brokenEscaped = RegExp(r'^\\d*\\.?\\d{0,2}'); // doubled backslashes
  final fixed = RegExp(r'\d*\.?\d{0,2}');

  for (final input in ['123.45', '250', '9.99', 'abc']) {
    String allowed(RegExp p) {
      final matches = p.allMatches(input).toList();
      // Simulate allow-formatter: banned regions = between/outside matches.
      final kept = StringBuffer();
      int prevEnd = 0;
      for (final m in matches) {
        kept.write(input.substring(prevEnd, m.start).replaceAll(RegExp(r'.'), ''));
        kept.write(m.group(0)!);
        prevEnd = m.end;
      }
      kept.write(input.substring(prevEnd).replaceAll(RegExp(r'.*'), ''));
      return kept.toString();
    }

    print('Input: "$input"');
    print('  OLD (anchored)  -> allowed text: "${allowed(brokenAnchored)}"');
    print('  OLD (2x bslash) -> allowed text: "${allowed(brokenEscaped)}"');
    print('  NEW (fixed)     -> allowed text: "${allowed(fixed)}"');
  }
}
