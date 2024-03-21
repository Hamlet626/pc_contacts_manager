import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import '../../providers/providers.dart';
import 'gcs_view.dart';

class GcDialog extends HookConsumerWidget {
  final Map<String,dynamic>group;
  const GcDialog({required this.group, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector=useState(<String>[]);
    final loading=useState(false);
    final allgcs=ref.watch(gCsProvider).value;
    return AlertDialog(title: const Text('Distribute'),
      scrollable: true,
      content: SizedBox(
          height: 600,
          width: 400,
          child:GCsView(selector: selector,dtbGroup: group,)),
      actions: [
        TextButton(onPressed: selector.value.isEmpty||loading.value?null:()=>sendProfile(context,loading,selector,allgcs!,false),
            child: Text('${selector.value.isEmpty?'':'${selector.value.length} distributes'} Confirm (no Logo)')),
        FilledButton(onPressed: selector.value.isEmpty||loading.value?null:()=>sendProfile(context,loading,selector,allgcs!,true),
            child: Text('${selector.value.isEmpty?'':'${selector.value.length} distributes'} Confirm'))
      ],
    );
  }

  Future sendProfile(BuildContext context, ValueNotifier<bool>loading,
      ValueNotifier<List<String>>selector, List<Map<String,dynamic>>allgcs, bool withLogo)async{
    loading.value=true;

    final res=await Future.wait(selector.value.map((gcid)async{
      try{
        final distRes=await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/distributeGcProfile'),
            headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
            body: json.encode({
              'gcId':gcid,
              'groups':[group['topic']],
              'updateFirebase':true,
              'logo':withLogo
            }));
        final jsonRes=json.decode(distRes.body);
        return {'success':jsonRes['success_groups']!=null,'message':jsonRes['message']};
      }catch(e,st){
        return {'success':false,'message':'unknown error:$e'};}
    }));

    if(res.every((e) => e['success'])) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.greenAccent,
          content: Text('successfully sent profiles!')));
    } else {
      loading.value=false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('sending \n${
              (List.generate(res.length, (i){
                if(res[i]['success'])return null;
                final gc=allgcs.singleWhere((e) => e['id']== selector.value[i]);
                return '${gc['First_Name']} ${gc['Last_Name']}: ${res[i]['message']}';
              })..removeWhere((v)=>v==null)).join(',\n')
          }\n failed!')));
    }
  }
}
