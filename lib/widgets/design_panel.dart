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
                    ? Column(
                        key: const ValueKey('angle'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Gradient angle: ${style.gradientAngleDeg.round()}°'),
                          Slider(
                            min: 0,
                            max: 360,
                            divisions: 24,
                            value: style.gradientAngleDeg,
                            label: '${style.gradientAngleDeg.round()}°',
                            onChanged: (v) =>
                                _set(() => style.gradientAngleDeg = v),
                          ),
                        ],
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
              Text('Eye stroke: ${style.eyeStrokeRatio.toStringAsFixed(2)}×'),
              Slider(
                min: 0.5,
                max: 1.5,
                divisions: 10,
                value: style.eyeStrokeRatio,
                label: '${style.eyeStrokeRatio.toStringAsFixed(2)}×',
                onChanged: (v) => _set(() => style.eyeStrokeRatio = v),
              ),
              Text(
                  'Eye corner roundness: ${style.eyeCornerRatio.toStringAsFixed(2)}×'),
              Slider(
                min: 0,
                max: 2,
                divisions: 10,
                value: style.eyeCornerRatio,
                label: '${style.eyeCornerRatio.toStringAsFixed(2)}×',
                onChanged: (v) => _set(() => style.eyeCornerRatio = v),
              ),
            ],
          ),
        ),
        _SectionCard(
          icon: Icons.image_outlined,
          title: 'Logo',
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
              const Text(
                  'Supported: PNG, JPEG, GIF, WebP, BMP, ICO, TIFF',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: style.logoBytes != null
                    ? Column(
                        key: const ValueKey('logo-opts'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Logo size: ${(style.logoSizeRatio * 100).round()}%'),
                          Slider(
                            min: 0.1,
                            max: 0.35,
                            value: style.logoSizeRatio,
                            onChanged: (v) =>
                                _set(() => style.logoSizeRatio = v),
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
                          Text(
                              'Logo border: ${(style.logoBorderWidth * 100).toStringAsFixed(1)}%'),
                          Slider(
                            min: 0,
                            max: 0.08,
                            value: style.logoBorderWidth,
                            onChanged: (v) =>
                                _set(() => style.logoBorderWidth = v),
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
                onChanged: (v) => _set(() => style.quietModules = v.round()),
              ),
              Text(
                  'Outer corner radius: ${(style.cornerRadiusRatio * 100).round()}%'),
              Slider(
                min: 0,
                max: 0.2,
                value: style.cornerRadiusRatio,
                label: '${(style.cornerRadiusRatio * 100).round()}%',
                onChanged: (v) => _set(() => style.cornerRadiusRatio = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText:
                        'Error correction (higher = more scan-resistant)'),
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
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _pickColor(context, color, onPicked),
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
