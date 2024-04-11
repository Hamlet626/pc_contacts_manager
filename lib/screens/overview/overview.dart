import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pc_wechat_manager/screens/overview/create_group_dialog.dart';
import 'gcs_view.dart';
import 'groups_view.dart';


class OverviewScreen extends HookConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt=Theme.of(context).textTheme;
    final ismb=MediaQuery.of(context).size.width<600;
    final tc=useTabController(initialLength: 2);

    return Scaffold(
      appBar: ismb?AppBar(
        title: TabBar(controller: tc,
            tabs: [Tab(text: 'Matching GCs',),Tab(text: 'Wechat Groups',)]),
        actions: [FilledButton.icon(
          onPressed: ()=>showDialog(context: context, builder: (context)=>const CreateGroupDialog()),
          icon: const Icon(Icons.add), label: const Text('WeChat Group'))
        ],):null,
      body: ismb?Padding(padding: EdgeInsets.only(top: 12),child: TabBarView(
          controller: tc,
            children: const [GCsView(),WcGroupsView()])):
      Padding(padding: const EdgeInsets.all(16),child:Row(children: [
        _buildView('All Matching GCs',const GCsView(),tt),
        const SizedBox(width: 30,),
        _buildView('All Wechat Groups',const WcGroupsView(),tt,
            action: FilledButton.icon(
                onPressed: ()=>showDialog(context: context, builder: (context)=>const CreateGroupDialog()),
                icon: const Icon(Icons.add), label: const Text('New'))),
      ],)),);
  }

  _buildView(String title,Widget child,TextTheme tt, {Widget? action})=>Expanded(child:
  Card(child:Column(children: [
    const SizedBox(height: 4,),
    Row(children: [
      Expanded(child: Center(child: Text(title,style: tt.headlineSmall))),
      action??const SizedBox(),
      const SizedBox(width: 8,),
    ],),
    Expanded(child: child)
  ],)));
}






