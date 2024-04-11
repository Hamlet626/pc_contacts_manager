import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:pc_wechat_manager/providers/providers.dart';
import 'package:pc_wechat_manager/screens/meetings.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'groups_dialog.dart';

class GCsView extends HookConsumerWidget {
  final ValueNotifier<List<String>>? selector;
  final Map<String,dynamic>? dtbGroup;
  const GCsView({this.selector,this.dtbGroup,super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQry=useState('');
    final debouncedInput = useDebounced(
      searchQry.value,
      const Duration(milliseconds: 500), // Set your desired timeout
    )?.toLowerCase();

    final teamsFilter=useState(<String>{});

    final gcs=ref.watch(gCsProvider).value?.where((e) =>
    '${e['First_Name']} ${e['Last_Name']}'.toLowerCase().contains(debouncedInput??'')&&
        (teamsFilter.value.isEmpty||teamsFilter.value.contains(e['team']))
    ).toList();

    final dbData=ref.watch(disburseDataProvider).value?.docs;
    final unholding=useState(false);

    final tt=Theme.of(context).textTheme;
    final cs=Theme.of(context).colorScheme;
    final list = gcs!=null?ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, i) {
        final dbMatches=dbData?.where((e) => e.id==gcs[i]['id']).toList();
        final gcDbData=dbMatches==null||dbMatches.isEmpty?null:dbMatches[0];
        final distributed=(gcDbData?.data()['distributed'] as List<dynamic>?)?.cast<String>();
        final requested=(gcDbData?.data()['requested'] as List<dynamic>?)?.cast<String>();

        final title=Text.rich(TextSpan(text: '${gcs[i]['First_Name']} ${gcs[i]['Last_Name']}',
            children: [TextSpan(text:'(${gcs[i]['team']})',style: tt.bodySmall?.copyWith(color: cs.onPrimaryContainer))]));

        final subtitle=Wrap(children: [
          if(gcs[i]['Match_Grade']!=null)Text('${gcs[i]['Match_Grade']}   '),
          if(distributed?.isNotEmpty==true)ActionChip(onPressed: (){},
              label:Text('${distributed!.length} distributed   ')),
          if(gcDbData?.data()['holdBy']!=null)ActionChip(onPressed: (){},
              label:Text('Hold:${gcDbData?.data()['holdBy']}')),
          if(requested?.isNotEmpty==true)ActionChip(onPressed: (){},
              label:Text('${requested!.length} requested')),
        ]);

        if(selector!=null) {
          final alreadyDtb=distributed?.contains(dtbGroup!['topic'])==true;
          final selected=selector!.value.contains(gcs[i]['id']);
          return CheckboxListTile(
            // enabled: !alreadyDtb,
            tristate: alreadyDtb,
            value: selected?true:alreadyDtb?null:false,
            onChanged: (v)=>selector!.value=List.of(!selected?
            (selector!.value..add(gcs[i]['id'])):(selector!.value..remove(gcs[i]['id']))),
            title: title,
            subtitle: subtitle,
          );
        } else {
          return ExpansionTile(
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            leading: dbData==null?const Icon(null):
            gcDbData==null?const Icon(Icons.circle):
            gcDbData.data()['holdBy']==null?const Icon(null):
            const Icon(Icons.stop_circle,color: Colors.redAccent,),

            title: InkWell(child: title,onTap: ()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/Leads/${gcs[i]['id']}'),),
            subtitle: subtitle,
            // trailing: TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>WcGroupDialog(gc:gcs[i])),
            //     child: const Text('Distribute')),
            children: [
              if(distributed?.isNotEmpty==true)...[
                Text('Distributed to:'),
                Text(distributed!.join(', '))
              ],
              Align(alignment: Alignment.centerRight,child: TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>WcGroupDialog(gc:gcs[i])),
                  child: const Text('Distribute')),),

              if(gcDbData?.data()['holdBy']!=null)
                Text('Hold by: ${gcDbData?.data()['holdBy']}'),
              if(requested?.isNotEmpty==true)...[
                Text('Currently Requested by:'),
                Text(requested!.join(', '))
              ],
              if(gcDbData?.data()['holdBy']!=null)
                Align(alignment: Alignment.centerRight,child: TextButton(
                    onPressed: unholding.value?null:()=>unhold(context,unholding,gcDbData?.data()['holdBy'],gcs[i]),
                    child: const Text('Un-hold')),),

              Align(alignment: Alignment.centerRight,child: FilledButton(onPressed: ()=>MeetingAdder.show(context,gc: gcs[i]), child: const Text('Add Meeting'))
              )
            ].expand((e) => [e,const SizedBox(height: 8)]).toList(),
          );}
      },
      separatorBuilder: (context, i)=>const Divider(),
      itemCount: gcs.length,
    ):const Center(child: CircularProgressIndicator());

    return Column(children: [
      TextField(onChanged: (v)=>searchQry.value=v,decoration: InputDecoration(prefixIcon: Icon(Icons.search)),),
      Wrap(children: [...teams.keys,'unknown'].map((e) => SizedBox(
          width: 160,
          child:
          CheckboxListTile(
              title: Text(e),
              value: teamsFilter.value.contains(e),
              onChanged: (v){
                final l=Set.of(teamsFilter.value);
                teamsFilter.value=v!?{...l,e}:(l..remove(e));
              }))).toList()
      ),
      Flexible(child: list)
    ],);
  }

  Widget leftText(String text)=>Align(alignment: Alignment.centerLeft,child:Text(text));

  Future<void> unhold(BuildContext context,ValueNotifier<bool>unholding,String wcGroupName,Map<String,dynamic> gc)async{
    unholding.value=true;

    try{
      await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/unHoldGcProfile'),
          headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
          body: json.encode({
            'gcId':gc['id'],
            'roomName':wcGroupName,
            'gcName':gc['First_Name'].substring(0, 1).toUpperCase() +
                gc['First_Name'].substring(1).toLowerCase(),
            'state':gc['State'].toUpperCase(),
          }));
    }catch(e,st){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 30),
          backgroundColor: Colors.red,
          content: Text('Un-Hold failed: $e',)));
    }
    unholding.value=false;
  }
}
