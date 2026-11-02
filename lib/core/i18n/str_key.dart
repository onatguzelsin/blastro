/// One translatable UI string. The keys are split over several enums (menu,
/// game, help) so each file stays small; every language must define a value
/// for every key, which `test/core/i18n/string_parity_test.dart` enforces.
abstract interface class StrKey implements Enum {}
