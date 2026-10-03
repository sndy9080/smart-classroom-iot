import 'package:flutter/material.dart';

class SmartSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String areaName;
  
  const SmartSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.areaName,
  });

  @override
  State<SmartSwitch> createState() => _SmartSwitchState();
}

class _SmartSwitchState extends State<SmartSwitch> {
  bool _isLoading = false;
  bool _localValue = false;
  
  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }
  
  @override
  void didUpdateWidget(SmartSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _localValue = widget.value;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Switch(
          value: _localValue,
          onChanged: _isLoading ? null : _handleChange,
        ),
        if (_isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
  
  void _handleChange(bool value) async {
    setState(() {
      _localValue = value;
      _isLoading = true;
    });
    
    // Call the callback
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
    
    // ✅ OPTIMIZED: Faster timeout for better UX
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }
}