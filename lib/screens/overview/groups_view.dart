import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pc_wechat_manager/providers/providers.dart';
import 'package:pc_wechat_manager/screens/overview/wechaty_login.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../meetings.dart';
import 'gcs_dialog.dart';

class WcGroupsView extends HookConsumerWidget {
  final ValueNotifier<List<String>>? selector;
  final Map<String,dynamic>? dtbGC;
  const WcGroupsView({this.selector,this.dtbGC, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQry=useState('');
    final debouncedInput = useDebounced(
      searchQry.value,
      const Duration(milliseconds: 500), // Set your desired timeout
    )?.toLowerCase();

    final groupsData=ref.watch(wcGroupsProvider);
    if(groupsData.error=="user not logged in") return const WcLogIn();
    final groups=groupsData.value?.where((e) =>
        [e['topic'], ...e['members']].any((e) => e.toLowerCase().contains(debouncedInput??''))
    ).toList();

    final dbData=ref.watch(disburseDataProvider).value?.docs;
    final mds=ref.watch(middleMenProvider(true)).value;
    final ips=ref.watch(iPsProvider(true)).value;

    final gcs=ref.watch(gCsProvider).value;


    final list = groups!=null?ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, i) {
        final ipMatch=ips?.where((e) => e['Wechat_Group_Name']==groups[i]['topic']).toList();
        final mdMatch=mds?.where((e) => e['Wechat_Group_Name']==groups[i]['topic']).toList();

        final distributed=dbData?.where((e) => (e.data()['distributed']??[]).contains(groups[i]['topic']));
        final holding=dbData?.where((e) => e.data()['holdBy']==groups[i]['topic']);
        final requested=dbData?.where((e) => (e.data()['requested']??[]).contains(groups[i]['topic']));

        final subtitle=Wrap(children: [
          if(distributed?.isNotEmpty==true)ActionChip(onPressed: (){},
              label:Text('${distributed!.length} distributed')),
          if(holding?.isNotEmpty==true)ActionChip(onPressed: (){},
              label:Text('${holding!.length} Holding')),
          if(requested?.isNotEmpty==true)ActionChip(onPressed: (){},
              label:Text('${requested!.length} requested')),
        ]);

        if(selector!=null) {
          final alreadyDtb=distributed!=null&&distributed.any((e) => e.id==dtbGC!['id']);
          final selected=selector!.value.contains(groups[i]['topic']);
          return CheckboxListTile(
            // enabled: !alreadyDtb,
            tristate: alreadyDtb,
            value: selected?true:alreadyDtb?null:false,
            onChanged: (v)=>selector!.value=List.of(!selected?
            (selector!.value..add(groups[i]['topic'])):(selector!.value..remove(groups[i]['topic']))),
            title: Text(groups[i]['topic']),
            subtitle: subtitle,
          );
        } else {
          return ExpansionTile(
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: mdMatch?.isNotEmpty==true?CircleAvatar(child: Text('MD'),):
            ipMatch?.isNotEmpty==true?CircleAvatar(child: Text('IP'),):Icon(null),

            title: InkWell(onTap:
            mdMatch?.isNotEmpty==true?()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/CustomModule21/${mdMatch![0]['id']}'):
            ipMatch?.isNotEmpty==true?()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/CustomModule7/${ipMatch![0]['id']}'):null,
              child: Text(groups[i]['topic']),),

            subtitle: subtitle,

            // trailing: TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>GcDialog(group:groups[i])),
            //     child: const Text('Distribute')),
            children: [
              if(distributed?.isNotEmpty==true)_fbGcsDetail('Distributed: ',distributed!,gcs),
              if(holding?.isNotEmpty==true)_fbGcsDetail('Holding: ',holding!,gcs),
              if(requested?.isNotEmpty==true)_fbGcsDetail('Requesting: ',requested!,gcs),
              Row(mainAxisAlignment:MainAxisAlignment.end, children: [
                TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>GcDialog(group:groups[i])),
                    child: const Text('Distribute')),
                FilledButton(onPressed: ()=>MeetingAdder.show(context,group: groups[i]), child: const Text('Add Meeting'))
              ],)
            ].expand((e) => [e,const SizedBox(height: 8)]).toList(),
          );
        }
      },
      separatorBuilder: (context, i)=>const Divider(),
      itemCount: groups.length,
    ):const Center(child: CircularProgressIndicator());

    return Column(children: [
      TextField(onChanged: (v)=>searchQry.value=v,decoration: InputDecoration(prefixIcon: Icon(Icons.search)),),
      Flexible(child: list)
    ],);
  }

  Widget _fbGcsDetail(String s, Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> gcsFbData, List<Map<String, dynamic>>? gcsCrmData){
    return Row(children: [
      Text(s),
      if(gcsCrmData!=null) Expanded(child: Text.rich(TextSpan(children: gcsFbData.map((fbGC){
        final crmGCIndex=gcsCrmData.indexWhere((crmGC) => crmGC['id']==fbGC.id);
        return TextSpan(text: crmGCIndex==-1?'Unknown GC':
        '${gcsCrmData[crmGCIndex]['First_Name']} ${gcsCrmData[crmGCIndex]['Last_Name']}',
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>launchUrlString('https://crm.zoho.com/crm/patriots/tab/Leads/${fbGC.id}')
        );
      }).expand((e) => [e, const TextSpan(text: ',  ')]).toList())))
    ],);
  }
}