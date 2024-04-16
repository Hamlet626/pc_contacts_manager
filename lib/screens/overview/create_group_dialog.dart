import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:pc_wechat_manager/providers/providers.dart';

class CreateGroupDialog extends HookConsumerWidget {
  const CreateGroupDialog({super.key});

  static final GCsRecRegex=RegExp(r'^https://crm\.zoho\.com/crm/patriots/tab/Potentials/\d+$');

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final ips=ref.watch(iPsProvider(false)).value??[];
    final mds=ref.watch(middleMenProvider(false)).value??[];

    final tc=useTextEditingController();
    final gctc=useTextEditingController();
    final gcErrorText=useState<String?>(null);
    final ipSelected=useState<Map<String,dynamic>?>(null);
    final mdSelected=useState<Map<String,dynamic>?>(null);

    final loading=useState(false);
    final groupNameError=useState<String?>(null);

    return AlertDialog(title: Text('New Group'),
        content: ConstrainedBox(constraints: BoxConstraints(minWidth: 500),
            child: Column(mainAxisSize:MainAxisSize.min,children: [
              TextField(controller:tc, decoration: InputDecoration(labelText: 'Group Name *',
                  errorText: groupNameError.value),),
              SizedBox(height: 32,),
              Row(children: [
                _CRMDropDown(ips,ipSelected,tc,['First_Name', 'Last_Name'],'IP'),
                SizedBox(width: 16,),
                _CRMDropDown(mds,mdSelected,tc,['Name'],'MdMen'),
              ],),
              TextField(controller:gctc, onChanged: (v){
                gcErrorText.value=v.isNotEmpty&&!GCsRecRegex.hasMatch(v)?'Invalid CRM GCs Link':null;
              }, decoration: InputDecoration(labelText: "Link with CRM GC (as Case Group)", errorText: gcErrorText.value,
                  hintText: "paste GCs' CRM link here, to link the group with CRM GC",
              ),),
        ])),
      // shape: RoundedRectangleBorder(
      //     borderRadius:
      //     BorderRadius.all(
      //         Radius.circular(10.0))),
      actions: [
        TextButton(onPressed: loading.value?null:()async{
          if(tc.text.isNotEmpty!=true){
            groupNameError.value='Please enter a group name';
            return;
          }else {
            groupNameError.value=null;
          }
          loading.value=true;
          final roomRes=await post(Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/wct/createGroup'),
              headers: {'wcKey': 'hamlet','Content-Type': 'application/json'},
              body: json.encode({
                'topic':tc.text,
                'ids':[
                  // '7881302089909614',//jim
                  '7881302871304371',//yuna
                  '7881299801162135',//cindy
                  '7881301769316343',//raye
                  // '7881300822021046'//big poppa
                ],
                if((gctc.text.isNotEmpty&&GCsRecRegex.hasMatch(gctc.text))||
                    ((mdSelected.value??(ipSelected.value))!=null))
                  'announceType':mdSelected.value!=null?1:ipSelected.value!=null?2:0
              }));
          if(roomRes.statusCode==200){
            final crmRes=await Future.wait([
              if(gctc.text.isNotEmpty&&GCsRecRegex.hasMatch(gctc.text))
                zohoUpdateRecWc('Deals', gctc.text.split('/').last, tc.text),
              if(ipSelected.value!=null)zohoUpdateRecWc('Intended_Parents', ipSelected.value!['id'], tc.text),
              if(mdSelected.value!=null)zohoUpdateRecWc('MiddleMen', mdSelected.value!['id'], tc.text),
            ]);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.green,
                content: Text('创建群组成功! 请刷新页面更新群组和IP/MiddleMen信息。')));
          }else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.red,
              content: Text('Create group failed!')));
          }
          loading.value=false;
          }, child: Text('Create'))],
    );
  }

  _CRMDropDown(List<Map<String,dynamic>> items,ValueNotifier<Map<String,dynamic>?> selected,
      TextEditingController tc,List<String>nameKeys,String label)=>
      Flexible(child: DropdownSearch(
    popupProps: const PopupProps.dialog(showSearchBox: true,searchDelay: Duration.zero),
    clearButtonProps: ClearButtonProps(isVisible: selected.value!=null),
    items: items,selectedItem: selected.value,
    itemAsString: (md)=>[...nameKeys, 'Wechat_Group_Name', 'Wechat_Alias']
        .map((e) => md[e]).join(' '),
    dropdownDecoratorProps: DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(labelText: "Link with CRM $label"),
    ),
    dropdownBuilder: (context, md)=>md==null?const SizedBox():Row(children: [
      Expanded(child: Text(nameKeys.map((e) => md[e]).join(' '))),
      Text(md?['Wechat_Group_Name']??'')
    ],),
    onChanged: (v){
      selected.value=v;
      if(v!=null)tc.text='培恩-${v['Name']}-配单群';
    },
  ));

  Future zohoUpdateRecWc(String moduleID,String rid,String wc)async{
    final r = json.decode(utf8.decode((
        await post(
            Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/zohoAPI'),
            headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
            body: json.encode({
              'method':'put',
              'url':'https://www.zohoapis.com/crm/v6/$moduleID/$rid',
              'data':{"data":[{"Wechat_Group_Name" :wc}]}
            }))).bodyBytes));
    if(r['data']==null)throw r;
    return r['data'];
  }
}
