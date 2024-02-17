import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:pc_wechat_manager/providers/providers.dart';
import 'package:url_launcher/url_launcher_string.dart';


class OverviewScreen extends HookConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt=Theme.of(context).textTheme;
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(16),child:Row(children: [
        _buildView('All Matching GCs',const GCsView(),tt),
        const SizedBox(width: 30,),
        _buildView('All Wechat Groups',const WcGroupsView(),tt),
      ],)),);
  }

  _buildView(String title,Widget child,TextTheme tt)=>Expanded(child:
  Card(child:Column(children: [
    Text(title,style: tt.headlineSmall),
    Expanded(child: child)
  ],)));
}


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
        TextButton(onPressed: loading.value?null:()async{
          loading.value=true;
          //todo: send api /gc

          final res=await Future.wait(selector.value.map((gcid)async{
            try{
              final distRes=await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/distrGcProfile'),
                  headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
                  body: json.encode({
                    'gcId':'https://www.zohoapis.com/crm/v3/coql',
                    'groups':[group['topic']],
                    'updateFirebase':true
                  }));
              return json.decode(distRes.body)['success_groups']!=null;
            }catch(e,st){return false;}
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
        }, child: const Text('Confirm'))
      ],
    );
  }
}

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

        final subtitle=Text.rich(TextSpan(text: '${gcs[i]['Match_Grade']??' '}   ',children: [
          if(distributed?.isNotEmpty==true)TextSpan(text:'${distributed!.length} distributed   '),
          if(requested?.isNotEmpty==true)TextSpan(text:'${requested!.length} requested'),
        ]));

        if(selector!=null) {
          final alreadyDtb=distributed?.contains(dtbGroup!['topic'])==true;

          return CheckboxListTile(
            enabled: !alreadyDtb,tristate: alreadyDtb,
            value: alreadyDtb?null:selector!.value.contains(gcs[i]['id']),
            onChanged: (v)=>selector!.value=List.of(v==true?
            (selector!.value..add(gcs[i]['id'])):(selector!.value..remove(gcs[i]['id']))),
            title: title,
            subtitle: subtitle,
          );
        } else {
        return ExpansionTile(
          leading: dbData==null?const Icon(null):
          gcDbData==null?const Icon(Icons.circle):
          gcDbData.data()['hold task']==null?const Icon(null):
          const Icon(Icons.stop_circle,color: Colors.redAccent,),

          title: InkWell(child: title,onTap: ()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/Leads/${gcs[i]['id']}'),),
          subtitle: subtitle,
          trailing: TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>WcGroupDialog(gc:gcs[i])),
              child: const Text('Distribute')),
          children: [
            if(distributed?.isNotEmpty==true)Row(children: [
              const Text('Distributed to:'),
              Expanded(child: Text(distributed!.join(', ')))
            ],),
            if(gcDbData?.data()['holdBy']!=null)
              Align(alignment: Alignment.centerLeft,child: Text('Hold by: ${gcDbData?.data()['holdBy']}')),
            if(requested?.isNotEmpty==true)Row(children: [
              const Text('Currently Requested by:'),
              Expanded(child: Text(requested!.join(', ')))
            ],),
          ].expand((e) => [e,const SizedBox(height: 8)]).toList(),
        );}
      },
      separatorBuilder: (context, i)=>const Divider(),
      itemCount: gcs.length,
    ):const Center(child: CircularProgressIndicator());

    return Column(children: [
      TextField(onChanged: (v)=>searchQry.value=v,),
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
}


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
        TextButton(onPressed: loading.value?null:()async{
          loading.value=true;
          //todo: send api /gc
          late Map<String,dynamic> data;
          try{
            final distRes=await post(Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/distributeGcProfile'),
              headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
              body: json.encode({
                'gcId':gc['id'],
                'groups':selector.value,
                'updateFirebase':true
              }));
            data=json.decode(distRes.body);
          }catch(e,st){
            data={'message':'Send profile error!'};
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
        }, child: const Text('Confirm'))
      ],
    );
  }
}

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
    if(groupsData.error=="user not logged in") return WcLogIn();
    final groups=groupsData.value?.where((e) =>
        [e['topic'], ...e['members']].any((e) => e.toLowerCase().contains(debouncedInput??''))
    ).toList();

    final dbData=ref.watch(disburseDataProvider).value?.docs;
    final mds=ref.watch(middleMenProvider).value;
    final ips=ref.watch(iPsProvider).value;

    final gcs=ref.watch(gCsProvider).value;


    final list = groups!=null?ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, i) {
        final ipMatch=ips?.where((e) => e['Wechat_Group_Name']==groups[i]['topic']).toList();
        final mdMatch=mds?.where((e) => e['Wechat_Group_Name']==groups[i]['topic']).toList();

        final distributed=dbData?.where((e) => (e.data()['distributed']??[]).contains(groups[i]['topic']));
        final holding=dbData?.where((e) => e.data()['holdBy']==groups[i]['topic']);
        final requested=dbData?.where((e) => (e.data()['requested']??[]).contains(groups[i]['topic']));

        final subtitle=Row(children: [
          if(distributed?.isNotEmpty==true)ActionChip(label:Text('${distributed!.length} distributed')),
          if(holding?.isNotEmpty==true)ActionChip(label:Text('${holding!.length} Holding')),
          if(requested?.isNotEmpty==true)ActionChip(label:Text('${requested!.length} requested')),
        ]);

        if(selector!=null) {
          final alreadyDtb=distributed!=null&&distributed.any((e) => e.id==dtbGC!['id']);

          return CheckboxListTile(
            enabled: !alreadyDtb,tristate: alreadyDtb,
            value: alreadyDtb?null:selector!.value.contains(groups[i]['topic']),
            onChanged: (v)=>selector!.value=List.of(v==true?
            (selector!.value..add(groups[i]['topic'])):(selector!.value..remove(groups[i]['topic']))),
            title: Text(groups[i]['topic']),
            subtitle: subtitle,
          );
        } else {
          return ExpansionTile(
            leading: mdMatch?.isNotEmpty==true?CircleAvatar(child: Text('MD'),):
            ipMatch?.isNotEmpty==true?CircleAvatar(child: Text('IP'),):Icon(null),

            title: InkWell(onTap:
            mdMatch?.isNotEmpty==true?()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/CustomModule21/${mdMatch![0]['id']}'):
            ipMatch?.isNotEmpty==true?()=>launchUrlString('https://crm.zoho.com/crm/patriots/tab/CustomModule7/${ipMatch![0]['id']}'):null,
              child: Text(groups[i]['topic']),),

            subtitle: subtitle,

            trailing: TextButton(onPressed: ()=>showDialog(context: context, builder: (contaxt)=>GcDialog(group:groups[i])),
                child: const Text('Distribute')),
            children: [
              if(distributed?.isNotEmpty==true)_fbGcsDetail('Distributed: ',distributed!,gcs),
              if(holding?.isNotEmpty==true)_fbGcsDetail('Holding: ',holding!,gcs),
              if(requested?.isNotEmpty==true)_fbGcsDetail('Requesting: ',requested!,gcs),
            ].expand((e) => [e,const SizedBox(height: 8)]).toList(),
        );
        }
      },
      separatorBuilder: (context, i)=>const Divider(),
      itemCount: groups.length,
    ):const Center(child: CircularProgressIndicator());

    return Column(children: [
      TextField(onChanged: (v)=>searchQry.value=v,),
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
          recognizer: TapGestureRecognizer()
            ..onTap = () =>launchUrlString('https://crm.zoho.com/crm/patriots/tab/Leads/${fbGC.id}')
        );
      }).toList())))
    ],);
  }
}


class WcLogIn extends HookConsumerWidget {
  const WcLogIn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final qrcode=useStream(Stream.periodic(Duration(seconds: 5), (n)async{
      return (await get(Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/getQRCode'),
          headers: {'wcKey':'hamlet'})).body;
    }).asyncMap((event) => event));

    final tc=useTextEditingController();
    final tt=Theme.of(context).textTheme;
    final loading=useState(false);
    final step=useState(0);

    return Column(crossAxisAlignment:CrossAxisAlignment.start,children: [
      const SizedBox(height: 32,),
      Text('@Stephanie to login her WECOM !',style: tt.headlineMedium,),
      Stepper(
        currentStep: step.value,
        onStepTapped: (i)=>step.value=i,
        controlsBuilder: (_,__)=>Container(),
          steps: [
        Step(isActive: true,
            title: const Text('Scan QR Code'),
            subtitle: Text.rich(TextSpan(
              text: 'Scan on WeCom to login to Wechaty bot, by clicking this',
              children: [
                TextSpan(text: '  link', style: tt.titleMedium?.copyWith(decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()
                      ..onTap = qrcode.data==null?null:() =>launchUrlString(qrcode.data!)),
              ],)),
            content: Column(children: [
              if(qrcode.data!=null)Text.rich(TextSpan(text: qrcode.data, style: tt.titleMedium?.copyWith(decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>launchUrlString(qrcode.data!))),
              const SizedBox(height: 8,),
              const Text('The link will update every 5 Secs. If the link expired, just wait for another 5 secs and click the link.')
            ],)
        ),

        Step(isActive: true,
            title: const Text('Enter Verify Code'),
            subtitle: const Text('If on mobile pops a 6 digit verify code, just enter it here (Sometimes Needed)'),
            content: Column(children: [
              TextField(controller: tc,decoration: InputDecoration(label: Text('6 digit code')),),
              const SizedBox(height: 8,),
              FilledButton.tonal(onPressed: loading.value?null:()async{
                loading.value=true;
                final r=await post(Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/setVeriCode'),
                    body: json.encode({'code':tc.text.trim(),}),
                    headers: {'Content-Type': 'application/json', 'wcKey':'hamlet'});
                if(r.statusCode==200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor:Colors.green,
                          content: Text('Send code: ${tc.text} succeed, please wait a while for backend to log in.')));
                }
                loading.value=false;
              }, child: const Text('Send to Verify')),
              const SizedBox(height: 8,),
              const Text('After sending the Virify Code, you may wait a while and do Step 3 to check logging in success.')
            ],)),

        Step(isActive: true,
            title: const Text('Refresh If Success'),
            subtitle: const Text('If showing logging in in anther location succeeded on WeCom/WeChat, refresh this page here'),
            content: FilledButton.icon(onPressed: ()=>ref.refresh(wcGroupsProvider.future),
              icon: const Icon(Icons.refresh), label: const Text('Click Me to Refresh'),)),
      ]),
    ],);
  }
}