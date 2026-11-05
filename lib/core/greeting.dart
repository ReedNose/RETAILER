/// "Good morning" until noon, "Good afternoon" until 5 pm, then "Good evening".
String greeting_for(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
