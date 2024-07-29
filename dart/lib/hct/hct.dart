// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:material_color_utilities/utils/color_utils.dart';

import 'cam16.dart';
import 'src/hct_solver.dart';
import 'viewing_conditions.dart';

/// The color system used by designers today is HSL, or hue, saturation, lightness.
/// HSL isn't remotely accurate, and doesn't try to be:
/// it was built to make computing colors fast on 1970s computers.
///
/// Our brand new, perceptually accurate, color system is called HCT,
/// which stands for hue, chroma, tone.
///
/// Even though HCT is brand new, it is built on existing work:
/// color science defines many perceptually accurate color spaces.
/// For simplicity, let's focus on two of them: `L* a* b`, also known as LCH
/// (lightness, chroma, hue), and CAM16.
///
/// HCT's lightness measure, tone, is the same as `L* a* b*`'s lightness.
/// Using that lightness measure, along with some math tricks,
/// meant we could measure contrast with HCT, directly integrating
/// contrast checker algorithms and accessibility requirements.
///
/// HCT's hue and colorfulness measures, hue and chroma, are the same as
/// CAM16's hue and chroma. You may wonder why we didn't just use L*a*b*'s
/// hue and chroma measures, then, we could have just use `L* a* b*`! However,
/// when we tried using it in design, `L* a* b*` was too inconsistent perceptually.
///
/// For the first time, designers have a color system that truly reflects
/// what users see, taking into account a range of variables to ensure
/// appropriate color contrast, accessibility standards, and consistent
/// lightness/colorfulness across hues.
class Hct {
  /// A degree value between 0 and 360, representing the color's angle
  /// as measured on a color wheel.
  final double hue;

  /// The perception-adjusted saturation.
  final double chroma;

  /// The perception-adjusted lightness.
  final double tone;

  /// [Hct.from] is similar to this constructor and additionally
  /// contains preloaded [Cam16] data. The object created by [Hct.from]
  /// also caches the result of [toInt] for efficient repeated access.
  const Hct({required this.hue, required this.chroma, required this.tone})
      : assert(
          0 <= hue && hue <= 360,
          'the "hue" should have a value between 0 and 360 degrees.',
        ),
        assert(
          chroma >= 0,
          'the "chroma" should be a non-negative number.',
        ),
        assert(
          0 <= tone && tone <= 100,
          'the "tone" should have a value between 0 and 100.',
        );

  /// HCT representation of [argb].
  factory Hct.fromInt(int argb) = _HctFromCam16.fromInt;

  /// 0 <= [hue] < 360; invalid values are corrected.
  /// 0 <= [chroma] <= ?; Informally, colorfulness. The color returned may be
  ///    lower than the requested chroma. Chroma has a different maximum for any
  ///    given hue and tone.
  /// 0 <= [tone] <= 100; informally, lightness. Invalid values are corrected.
  factory Hct.from(double hue, double chroma, double tone) {
    return Hct.fromInt(HctSolver.solveToInt(hue, chroma, tone));
  }

  static const Hct black = _Black();

  /// The color in standard ARGB format.
  ///
  /// Can be used in Flutter's `Color()` constructor.
  int toInt() => HctSolver.solveToInt(hue, chroma, tone);

  /// Translate a color into different [ViewingConditions].
  ///
  /// Colors change appearance. They look different with lights on versus off,
  /// the same color, as in hex code, on white looks different when on black.
  /// This is called color relativity, most famously explicated by Josef Albers
  /// in Interaction of Color.
  ///
  /// In color science, color appearance models can account for this and
  /// calculate the appearance of a color in different settings. HCT is based on
  /// CAM16, a color appearance model, and uses it to make these calculations.
  ///
  /// See [ViewingConditions.make] for parameters affecting color appearance.
  Hct inViewingConditions(ViewingConditions vc) {
    final _HctFromCam16 cam16 = _HctFromCam16.fromInt(toInt());
    return cam16.inViewingConditions(vc);
  }
}

class _HctFromCam16 extends Cam16 implements Hct {
  _HctFromCam16(
    super.hue,
    super.chroma,
    this.tone,
    super.j,
    super.q,
    super.m,
    super.s,
    super.jstar,
    super.astar,
    super.bstar,
  );

  late final _argb = HctSolver.solveToInt(hue, chroma, tone);

  @override
  int toInt() => _argb;

  factory _HctFromCam16.fromInt(int argb) {
    final [x, y, z] = ColorUtils.xyzFromArgb(argb);
    final tone = ColorUtils.lstarFromY(y);

    final Cam16(:hue, :chroma, :j, :q, :m, :s, :jstar, :astar, :bstar) =
        Cam16.fromXyz(x, y, z);

    return _HctFromCam16(hue, chroma, tone, j, q, m, s, jstar, astar, bstar);
  }

  @override
  final double tone;

  @override
  String toString() => 'H${hue.round()} C${chroma.round()} T${tone.round()}';

  @override
  Hct inViewingConditions(ViewingConditions vc) {
    // 1. Use CAM16 to find XYZ coordinates of color in specified VC.
    final [x, y, z] = xyzInViewingConditions(vc);

    // 2. Create CAM16 of those XYZ coordinates in default VC.
    final Cam16(:hue, :chroma) = Cam16.fromXyz(x, y, z);

    // 3. Create HCT from:
    // - CAM16 using default VC with XYZ coordinates in specified VC.
    // - L* converted from Y in XYZ coordinates in specified VC.
    return Hct(
      hue: hue,
      chroma: chroma,
      tone: ColorUtils.lstarFromY(y),
    );
  }
}

class _Black implements Hct {
  const _Black();

  @override
  double get hue => 0.0;

  @override
  double get chroma => 0.0;

  @override
  double get tone => 0.0;

  static const argb = 0xFF000000;

  @override
  int toInt() => argb;

  @override
  Hct inViewingConditions(ViewingConditions vc) {
    return _HctFromCam16.fromInt(argb).inViewingConditions(vc);
  }
}
