import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';

import 'groups_view.dart';

class WcGroupDialog extends HookConsumerWidget {
  final Map<String,dynamic>gc;
  const WcGroupDialog({required this.gc, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector=useState(<String>[]);
    final loading=useState(false);
    return AlertDialog(title: const Text('Distribute to'),
      scrollable: true,
      content: SizedBox(
          height: 600,
          width: 400,
          child:WcGroupsView(selector: selector,dtbGC: gc,)),
      actions: [
        TextButton(onPressed: selector.value.isEmpty||loading.value?null:()=>sendProfile(context,loading,selector,false),
            child: Text('${selector.value.isEmpty?'':'${selector.value.length} distributes'} Confirm (no Logo)')),
        FilledButton(onPressed: selector.value.isEmpty||loading.value?null:()=>sendProfile(context,loading,selector,true),
            child: Text('${selector.value.isEmpty?'':'${selector.value.length} distributes'} Confirm'))
      ],
    );
  }

  sendProfile(BuildContext context,ValueNotifier<bool>loading,ValueNotifier<List<String>>selector,bool withLogo)async{
    loading.value=true;

    late Map<String,dynamic> data;
    try{
      final distRes=await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/distributeGcProfile'),
          headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
          body: json.encode({
            'gcId':gc['id'],
            'groups':selector.value,
            'updateFirebase':true,
            'logo':withLogo
          }));
      data=json.decode(distRes.body);
    }catch(e,st){
      data={'message':'Send profile error!\n$e'};
    }

    final success=data['success_groups']!=null&&data['success_groups'].length==selector.value.length;
    if(success){
      Navigator.pop(context);
    }else{
      loading.value=false;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        duration: Duration(seconds: 30),
        backgroundColor: success?Colors.greenAccent:Colors.red,
        content: Text(data['message'],)));
  }
}