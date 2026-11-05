/// Rounds to whole cents, so sums of prices never print as 14.999999999.
double round_money(double value) => (value * 100).round() / 100;
