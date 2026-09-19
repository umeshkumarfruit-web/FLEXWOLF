import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flutter/material.dart';

class FlexwolfHeader extends StatelessWidget implements PreferredSizeWidget {
  const FlexwolfHeader({this.actions = const <Widget>[], super.key});

  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      centerTitle: true,
      titleSpacing: 0,
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: FlexwolfLogo(compact: true),
      ),
      leadingWidth: 52,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'Open menu',
          icon: const Icon(Icons.menu, size: 25),
          onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
      ),
      actions: [
        ...actions,
        const SizedBox(width: AppSpacing.xxs),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(AppBorders.thin),
        child: Divider(height: AppBorders.thin, thickness: AppBorders.thin),
      ),
    );
  }
}
