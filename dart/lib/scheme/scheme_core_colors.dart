import 'package:material_color_utilities/dynamiccolor/dynamic_scheme.dart';
import 'package:material_color_utilities/dynamiccolor/variant.dart';
import 'package:material_color_utilities/hct/hct.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';

class SchemeCoreColors implements DynamicScheme {
  @override
  final bool isDark;

  @override
  final double contrastLevel;

  final String _variant;
  @override
  Variant get variant => Variant.fromLabel(_variant);

  final Hct? primaryCore;
  final Hct? secondaryCore;
  final Hct? tertiaryCore;
  final Hct? errorCore;
  final Hct? neutralCore;
  final Hct? outlineCore;

  @override
  final Hct sourceColorHct;

  const SchemeCoreColors({
    this.isDark = false,
    this.contrastLevel = 0.0,
    required String variant,
    this.primaryCore,
    this.secondaryCore,
    this.tertiaryCore,
    this.errorCore,
    this.neutralCore,
    this.outlineCore,
  })  : _variant = variant,
        sourceColorHct = primaryCore ?? neutralCore ?? outlineCore ?? Hct.black;

  TonalPalette fromSeed(Hct? seedColor) {
    return DynamicScheme.fromVariant(
      sourceColorHct: seedColor ?? sourceColorHct,
      variant: _variant,
      isDark: isDark,
      contrastLevel: contrastLevel,
    ).primaryPalette;
  }

  @override
  TonalPalette get errorPalette => switch (errorCore) {
        final hct? => TonalPalette.fromHct(hct),
        null => TonalPalette.of(25.0, 84.0),
      };

  @override
  TonalPalette get primaryPalette => fromSeed(primaryCore);

  @override
  TonalPalette get secondaryPalette => fromSeed(secondaryCore);

  @override
  TonalPalette get tertiaryPalette => fromSeed(tertiaryCore);

  @override
  TonalPalette get neutralPalette => fromSeed(neutralCore);

  @override
  TonalPalette get neutralVariantPalette => fromSeed(outlineCore);

  @override
  int get sourceColorArgb => sourceColorHct.toInt();
}
