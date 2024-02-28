import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import 'gcs_view.dart';

class GcDialog extends HookConsumerWidget {
  final Map<String,dynamic>group;
  const GcDialog({required this.group, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector=useState(<String>[]);
    final loading=useState(false);
    return AlertDialog(title: const Text('Distribute'),
      scrollable: true,
      content: SizedBox(
          height: 600,
          width: 400,
          child:GCsView(selector: selector,dtbGroup: group,)),
      actions: [
        TextButton(onPressed: selector.value.isEmpty||loading.value?null:()async{
          loading.value=true;
          //todo: send api /gc

          final res=await Future.wait(selector.value.map((gcid)async{
            try{
              final distRes=await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/distributeGcProfile'),
                  headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
                  body: json.encode({
                    'gcId':gcid,
                    'groups':[group['topic']],
                    'updateFirebase':true
                  }));
              return json.decode(distRes.body)['success_groups']!=null;
            }catch(e,st){
              return false;}
          }));

          if(res.every((e) => e)) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.greenAccent,
                content: Text('successfully sent profiles!')));
          } else {
            loading.value=false;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.red,
                content: Text('sending ${
                    (List.generate(res.length, (i) => res[i]?null:selector.value[i])..removeWhere((v)=>v==null)).join(', ')
                } failed!')));
          }
        }, child: Text('${selector.value.isEmpty?'':'${selector.value.length} distributes'} Confirm'))
      ],
    );
  }
}