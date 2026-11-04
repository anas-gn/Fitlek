/// Legacy bookings inherited a partner/company address, not a chosen venue.
String sessionLocationLabel({String? location, String? companyName}) {
  const arranged = 'Location to be arranged with coach in messages';
  if (companyName?.trim().isNotEmpty == true) return arranged;
  switch (location?.trim()) {
    case 'home':
      return 'Home visit — arrange address with coach in messages';
    case 'gym':
      return "Coach's gym";
    case null:
    case '':
    case 'To be defined':
      return arranged;
    default:
      return location!.trim();
  }
}
