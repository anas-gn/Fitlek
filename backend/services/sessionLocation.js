export function resolveSessionLocation(choice, gym) {
  if (choice === 'gym') {
    const name = gym?.gymName?.trim();
    if (!name) throw new Error('This coach has no associated gym. Choose another location.');
    return [name, gym.gymAddress?.trim()].filter(Boolean).join(' · ');
  }
  if (choice === 'home') return 'Home visit — arrange address with coach in messages';
  return 'Location to be arranged with coach in messages';
}

// Older bookings inherited an advisor/company address rather than a chosen venue.
// Present a neutral location without changing the stored reservation.
export function presentSessionLocation(reservation) {
  if (!reservation?.companyName?.trim()) return reservation;
  return {...reservation, location: 'Location to be arranged with coach in messages'};
}
