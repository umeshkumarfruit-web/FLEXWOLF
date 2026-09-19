import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/core/widgets/flexwolf_header.dart';
import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.actions = const <Widget>[],
    this.bottomNavigationBar,
    this.drawer,
    super.key,
  });

  final Widget body;
  final List<Widget> actions;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlexwolfHeader(actions: actions),
      drawer: drawer,
      body: ResponsiveSafeArea(child: FocusTraversalGroup(child: body)),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
