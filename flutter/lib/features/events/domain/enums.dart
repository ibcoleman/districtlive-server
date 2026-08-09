// ignore_for_file: constant_identifier_names

enum PriceTier {
  FREE,
  UNDER_15,
  PRICE_15_TO_30,
  OVER_30;
}

enum AgeRestriction {
  ALL_AGES,
  EIGHTEEN_PLUS,
  TWENTY_ONE_PLUS;
}

enum EventStatus {
  ACTIVE,
  CANCELLED,
  POSTPONED,
  RESCHEDULED;
}

enum EventType {
  CONCERT,
  ALBUM_RELEASE,
  SHOWCASE,
  TRIBUTE,
  DJ_SET,
  OTHER;
}

enum SourceType {
  TICKETMASTER_API,
  BANDSINTOWN_API,
  VENUE_SCRAPER,
  MANUAL,
  DICE_FM;
}
