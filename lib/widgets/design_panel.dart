import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/qr_style.dart';

/// Stage 1 extraction: grouped design controls (Colors / Shapes / Logo /
/// Advanced). Pure UI — every control mutates [style] in place and calls
/// [onChanged] so HomeScreen rebuilds + preview updates. No payload, matrix,
/// or export logic lives here.
class DesignPanel extends StatelessWidget {
  final QrStyle style;
  final VoidCallback onChanged;
  final VoidCallback onPickLogo;

  const DesignPanel({
    super.key,
    required this.style,
    required this.onChanged,
    required this.onPickLogo,
  });

  Future<void> _pickColor(
      BuildContext context, Color current, ValueChanged<Color> onPicked) async {
    Color temp = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onPicked(temp);
              Navigator.pop(ctx);
              onChanged();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          icon: Icons.palette_outlined,
          title: 'Colors',
          hint: 'Dark modules on a light background scan most reliably.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: _colorTile(
                        'Foreground',
                        style.foregroundColor,
                        (c) => _set(() => style.foregroundColor = c),
                        context)),
                const SizedBox(width: 8),
                Expanded(
                    child: _colorTile(
                        'Background',
                        style.backgroundColor,
                        (c) => _set(() => style.backgroundColor = c),
                        context)),
              ]),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<QrGradientType>(
                    decoration:
                        const InputDecoration(labelText: 'Gradient'),
                    value: style.gradientType,
                    items: const [
                      DropdownMenuItem(
                          value: QrGradientType.none, child: Text('None')),
                      DropdownMenuItem(
                          value: QrGradientType.linear,
                          child: Text('Linear')),
                      DropdownMenuItem(
                          value: QrGradientType.radial,
                          child: Text('Radial')),
                    ],
                    onChanged: (v) => _set(() => style.gradientType = v!),
                  ),
                ),
                const SizedBox(width: 8),
                if (style.gradientType != QrGradientType.none)
                  Expanded(
                      child: _colorTile(
                          'Gradient 2',
                          style.gradientColor2,
                          (c) => _set(() => style.gradientColor2 = c),
                          context)),
              ]),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: style.gradientType == QrGradientType.linear
                    ? MergeSemantics(
                        key: const ValueKey('angle'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Gradient angle: ${style.gradientAngleDeg.round()}°'),
                            Slider(
                              min: 0,
                              max: 360,
                              divisions: 24,
                              value: style.gradientAngleDeg,
                              label:
                                  '${style.gradientAngleDeg.round()}°',
                              semanticFormatterCallback: (v) =>
                                  '${v.round()} degrees',
                              onChanged: (v) =>
                                  _set(() => style.gradientAngleDeg = v),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-angle')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Background gradient'),
                value: style.backgroundGradient,
                onChanged: (v) => _set(() => style.backgroundGradient = v),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: style.backgroundGradient
                    ? _colorTile(
                        'Background 2',
                        style.backgroundGradientColor2,
                        (c) =>
                            _set(() => style.backgroundGradientColor2 = c),
                        context,
                        key: const ValueKey('bg2'))
                    : const SizedBox.shrink(key: ValueKey('no-bg2')),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Custom eye colors'),
                value: style.useCustomEyeColor,
                onChanged: (v) => _set(() => style.useCustomEyeColor = v),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: style.useCustomEyeColor
                    ? Row(
                        key: const ValueKey('eyecolors'),
                        children: [
                          Expanded(
                              child: _colorTile(
                                  'Eye frame',
                                  style.eyeFrameColor,
                                  (c) => _set(() => style.eyeFrameColor = c),
                                  context)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _colorTile(
                                  'Eye ball',
                                  style.eyeBallColor,
                                  (c) => _set(() => style.eyeBallColor = c),
                                  context)),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no-eyecolors')),
              ),
            ],
          ),
        ),
        _SectionCard(
          icon: Icons.category_outlined,
          title: 'Shapes',
          hint: 'Square dots and eyes scan most reliably.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<QrBodyShape>(
                decoration:
                    const InputDecoration(labelText: 'Body (dot) shape'),
                value: style.bodyShape,
                items: QrBodyShape.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => _set(() => style.bodyShape = v!),
              ),
              DropdownButtonFormField<QrEyeFrameShape>(
                decoration:
                    const InputDecoration(labelText: 'Eye frame shape'),
                value: style.eyeFrameShape,
                items: QrEyeFrameShape.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => _set(() => style.eyeFrameShape = v!),
              ),
              DropdownButtonFormField<QrEyeBallShape>(
                decoration:
                    const InputDecoration(labelText: 'Eye ball shape'),
                value: style.eyeBallShape,
                items: QrEyeBallShape.values
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => _set(() => style.eyeBallShape = v!),
              ),
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Eye stroke: ${style.eyeStrokeRatio.toStringAsFixed(2)}×'),
                    Slider(
                      min: 0.5,
                      max: 1.5,
                      divisions: 10,
                      value: style.eyeStrokeRatio,
                      label:
                          '${style.eyeStrokeRatio.toStringAsFixed(2)}×',
                      semanticFormatterCallback: (v) =>
                          '${v.toStringAsFixed(2)} times',
                      onChanged: (v) =>
                          _set(() => style.eyeStrokeRatio = v),
                    ),
                    Text(
                        'Eye corner roundness: ${style.eyeCornerRatio.toStringAsFixed(2)}×'),
                    Slider(
                      min: 0,
                      max: 2,
                      divisions: 10,
                      value: style.eyeCornerRatio,
                      label:
                          '${style.eyeCornerRatio.toStringAsFixed(2)}×',
                      semanticFormatterCallback: (v) =>
                          '${v.toStringAsFixed(2)} times',
                      onChanged: (v) =>
                          _set(() => style.eyeCornerRatio = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _SectionCard(
          icon: Icons.image_outlined,
          title: 'Logo',
          hint: 'Logos cover part of the code — pair large logos with higher error correction.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ElevatedButton.icon(
                  onPressed: onPickLogo,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add logo'),
                ),
                if (style.logoBytes != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Remove logo',
                    onPressed: () => _set(() => style.logoBytes = null),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(style.logoBytes as Uint8List,
                        width: 40, height: 40, fit: BoxFit.cover),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(
                  'Supported: PNG, JPEG, GIF, WebP, BMP, ICO, TIFF',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: style.logoBytes != null
                    ? Column(
                        key: const ValueKey('logo-opts'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MergeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Logo size: ${(style.logoSizeRatio * 100).round()}%'),
                                Slider(
                                  min: 0.1,
                                  max: 0.35,
                                  value: style.logoSizeRatio,
                                  label:
                                      '${(style.logoSizeRatio * 100).round()}%',
                                  semanticFormatterCallback: (v) =>
                                      '${(v * 100).round()} percent',
                                  onChanged: (v) =>
                                      _set(() => style.logoSizeRatio = v),
                                ),
                              ],
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title:
                                const Text('Clear background behind logo'),
                            value: style.removeBackgroundBehindLogo,
                            onChanged: (v) => _set(
                                () => style.removeBackgroundBehindLogo = v),
                          ),
                          DropdownButtonFormField<QrLogoShape>(
                            decoration: const InputDecoration(
                                labelText: 'Logo shape'),
                            value: style.logoShape,
                            items: QrLogoShape.values
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s.name)))
                                .toList(),
                            onChanged: (v) =>
                                _set(() => style.logoShape = v!),
                          ),
                          MergeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Logo border: ${(style.logoBorderWidth * 100).toStringAsFixed(1)}%'),
                                Slider(
                                  min: 0,
                                  max: 0.08,
                                  value: style.logoBorderWidth,
                                  label:
                                      '${(style.logoBorderWidth * 100).toStringAsFixed(1)}%',
                                  semanticFormatterCallback: (v) =>
                                      '${(v * 100).toStringAsFixed(1)} percent',
                                  onChanged: (v) => _set(
                                      () => style.logoBorderWidth = v),
                                ),
                              ],
                            ),
                          ),
                          if (style.logoBorderWidth > 0)
                            _colorTile(
                                'Border color',
                                style.logoBorderColor,
                                (c) =>
                                    _set(() => style.logoBorderColor = c),
                                context),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('no-logo')),
              ),
            ],
          ),
        ),
        _SectionCard(
          icon: Icons.tune_outlined,
          title: 'Advanced',
          hint: 'Tune scannability vs. style. When in doubt, keep defaults.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Quiet zone: ${style.quietModules} modules (4 recommended)'),
                    Slider(
                      min: 0,
                      max: 8,
                      divisions: 8,
                      value: style.quietModules.toDouble(),
                      label: '${style.quietModules}',
                      semanticFormatterCallback: (v) =>
                          '${v.round()} modules',
                      onChanged: (v) =>
                          _set(() => style.quietModules = v.round()),
                    ),
                  ],
                ),
              ),
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Outer corner radius: ${(style.cornerRadiusRatio * 100).round()}%'),
                    Slider(
                      min: 0,
                      max: 0.2,
                      value: style.cornerRadiusRatio,
                      label:
                          '${(style.cornerRadiusRatio * 100).round()}%',
                      semanticFormatterCallback: (v) =>
                          '${(v * 100).round()} percent',
                      onChanged: (v) =>
                          _set(() => style.cornerRadiusRatio = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText:
                        'Error correction (higher = more scan-resistant)',
                    helperText:
                        'Higher error-correction allows a bigger logo but reduces readable area.',
                    helperMaxLines: 2),
                value: style.errorCorrectionLevel,
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('L — ~7%')),
                  DropdownMenuItem(value: 'M', child: Text('M — ~15%')),
                  DropdownMenuItem(
                      value: 'Q', child: Text('Q — ~25%')),
                  DropdownMenuItem(
                      value: 'H',
                      child: Text('H — ~30% (recommended with logo)')),
                ],
                onChanged: (v) =>
                    _set(() => style.errorCorrectionLevel = v!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _set(void Function() mutate) {
    mutate();
    onChanged();
  }

  Widget _colorTile(String label, Color color, ValueChanged<Color> onPicked,
      BuildContext context,
      {Key? key}) {
    final scheme = Theme.of(context).colorScheme;
    final hex =
        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Semantics(
        button: true,
        label: '$label color',
        value: hex,
        hint: 'Double-tap to pick a new color',
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _pickColor(context, color, onPicked),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: scheme.outline),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, size: 20, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        initiallyExpanded: true,
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [child],
      ),
    );
  }
}
