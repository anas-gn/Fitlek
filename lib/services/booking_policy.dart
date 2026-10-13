bool hasBookingLeadTime(DateTime start, {DateTime? now}) =>
    start.difference(now ?? DateTime.now()) > const Duration(hours: 1);
