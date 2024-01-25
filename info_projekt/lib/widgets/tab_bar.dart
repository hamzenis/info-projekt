import 'package:flutter/material.dart';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';

class TabBarClass extends StatelessWidget {
  final List<Widget> tabs;
  final List<Widget> tabBarViews;

  TabBarClass({required this.tabs, required this.tabBarViews});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: ContainedTabBarView(
        tabs: tabs,
        views: tabBarViews,
        onChange: (index) => print(index),
      ),
    );
  }
}
