import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import '../../providers/providers.dart';
import 'groups_view.dart';

class UpdateAnnounceDialog extends HookConsumerWidget {
  const UpdateAnnounceDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector=useState(<String>[]);
    final loading=useState(false);
    final searchQry=useState('');

    final debouncedInput = useDebounced(
      searchQry.value,
      const Duration(milliseconds: 500), // Set your desired timeout
    )?.toLowerCase();
    final groupsData=ref.watch(wcGroupsProvider);
    final groups=groupsData.value?.where((e) =>
        [e['topic'], ...e['members']].any((e) => e.toLowerCase().contains(debouncedInput??''))
    ).toList();

    return AlertDialog(title: const Text('Update Announcement'),
      scrollable: true,
      content: SizedBox(
          height: 600,
          width: 400,
          child:Column(children: [
            TextField(onChanged: (v)=>searchQry.value=v,decoration: InputDecoration(prefixIcon: Icon(Icons.search)),),
            CheckboxListTile(value: selector.value.length==groupsData.value?.length,
                title: Text('All'), onChanged: (v){
              if(v!)selector.value=groupsData.value!.map((e) => e['topic']as String).toList();
              else selector.value=[];
            }),
            Expanded(child: ListView.separated(
            shrinkWrap: true,
            itemBuilder: (context, i) {

                final selected=selector.value.contains(groups[i]['topic']);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (v)=>selector.value=List.of(!selected?
                  (selector.value..add(groups[i]['topic'])):(selector.value..remove(groups[i]['topic']))),
                  title: Text(groups[i]['topic']),
                );
            },
            separatorBuilder: (context, i)=>const Divider(),
            itemCount: groups!.length,
          ))
          ])),
      actions: [
        FilledButton(onPressed: selector.value.isEmpty||loading.value?null:()=>updateAnnounce(context,loading,selector),
            child: const Text('Update Announcement'))
      ],
    );
  }

  updateAnnounce(BuildContext context,ValueNotifier<bool>loading,ValueNotifier<List<String>>selector)async{
    loading.value=true;

    final res=await Future.wait(selector.value.map((e) => post(
          Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/wct/updateAnnounce'),
          headers: {'wcKey': 'hamlet','Content-Type': 'application/json'},
          body: json.encode({
            'topic':e,
          }))));

    final failed=res.map((e) => e.statusCode<300?0:1).reduce((v, e) => v+e);
    if(failed==0){
      Navigator.pop(context);
    }else{
      final removed=selector.value.where((e) => res[selector.value.indexOf(e)].statusCode<300);
      selector.value=List.of(selector.value)..removeWhere((e) => removed.contains(e));
      loading.value=false;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: Duration(seconds: 30),
        backgroundColor: failed==0?Colors.greenAccent:Colors.red,
        content: Text(failed==0?'update success!':'$failed groups failed!',)));
  }
}