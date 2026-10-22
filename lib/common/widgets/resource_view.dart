import 'app_text.dart';
import 'package:flutter/material.dart';
import '../../core/bloc/resource_controller.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ResourceView<T> extends StatelessWidget {
  const ResourceView({
    super.key,
    required this.controller,
    required this.builder,
  });
  final ResourceController<T> controller;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.data != null) {
        return builder(context, controller.data as T);
      }
      if (controller.error != null) {
        return Center(
          child: Padding(
            padding: AppInsets.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'Unable to load content.',
                  style: AppTextStyles.body,
                ),
                TextButton(
                  onPressed: controller.load,
                  child: const AppText('Try again'),
                ),
              ],
            ),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    },
  );
}
