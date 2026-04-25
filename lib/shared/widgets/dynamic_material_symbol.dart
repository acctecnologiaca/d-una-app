import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:d_una_app/core/utils/material_symbols_helper.dart';
import 'package:material_symbols_icons/symbols.dart';

class DynamicMaterialSymbol extends StatefulWidget {
  final String? symbolName;
  final double size;
  final Color? color;
  final String style;
  final bool showFallback;

  const DynamicMaterialSymbol({
    super.key,
    required this.symbolName,
    this.size = 24.0,
    this.color,
    this.style = 'outlined',
    this.showFallback = true,
  });

  @override
  State<DynamicMaterialSymbol> createState() => _DynamicMaterialSymbolState();
}

class _DynamicMaterialSymbolState extends State<DynamicMaterialSymbol> {
  String? _svgContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(DynamicMaterialSymbol oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbolName != widget.symbolName ||
        oldWidget.style != widget.style) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    if (!mounted) return;

    final name = widget.symbolName;
    if (name == null || name.isEmpty) {
      if (mounted) {
        setState(() {
          _svgContent = null;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cacheDir = await getTemporaryDirectory();
      final iconDir = Directory(
        p.join(cacheDir.path, 'material_symbols_cache'),
      );
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }

      final fileName = '${name}_${widget.style}.svg';
      final localFile = File(p.join(iconDir.path, fileName));

      if (await localFile.exists()) {
        final content = await localFile.readAsString();
        if (mounted) {
          setState(() {
            _svgContent = content;
            _isLoading = false;
          });
        }
        return;
      }

      // If not in cache, download
      final url = MaterialSymbolsHelper.getSvgUrl(name, widget.style);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final content = response.body;
        // Basic SVG validation (should start with <svg)
        if (content.trim().startsWith('<svg')) {
          await localFile.writeAsString(content);
          if (mounted) {
            setState(() {
              _svgContent = content;
              _isLoading = false;
            });
          }
          return;
        }
      }
      throw Exception('Failed to download or invalid SVG');
    } catch (e) {
      if (mounted) {
        setState(() {
          _svgContent = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Padding(
          padding: EdgeInsets.all(widget.size * 0.2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color:
                widget.color?.withValues(alpha: 0.5) ??
                Theme.of(context).primaryColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    if (_svgContent != null) {
      return SvgPicture.string(
        _svgContent!,
        width: widget.size,
        height: widget.size,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
      );
    }

    // Fallback logic
    if (widget.showFallback) {
      return Icon(Symbols.package_2, size: widget.size, color: widget.color);
    }

    return const SizedBox.shrink();
  }
}
