import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:pc_wechat_manager/providers/providers.dart';

class CreateGroupDialog extends HookConsumerWidget {
  const CreateGroupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final ips=ref.watch(iPsProvider(false)).value??[];
    final mds=ref.watch(middleMenProvider(false)).value??[];

    final tc=useTextEditingController();
    final ipSelected=useState<Map<String,dynamic>?>(null);
    final mdSelected=useState<Map<String,dynamic>?>(null);

    final loading=useState(false);

    return AlertDialog(title: Text('New Group'),
        content: ConstrainedBox(constraints: BoxConstraints(minWidth: 500),
            child: Column(mainAxisSize:MainAxisSize.min,children: [
          TextField(controller:tc, decoration: InputDecoration(labelText: 'Group Name'),),
          SizedBox(height: 16,),
          Row(children: [
            _CRMDropDown(ips,ipSelected,tc,['First_Name', 'Last_Name']),
            SizedBox(width: 16,),
            _CRMDropDown(mds,mdSelected,tc,['Name']),
          ],),
        ])),
      // shape: RoundedRectangleBorder(
      //     borderRadius:
      //     BorderRadius.all(
      //         Radius.circular(10.0))),
      actions: [
        TextButton(onPressed: ()async{
          if(tc.text.isNotEmpty!=true)return;
          loading.value=true;
          final roomRes=await post(Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/wct/createGroup'),
              headers: {'wcKey': 'hamlet','Content-Type': 'application/json'},
              body: json.encode({
                'topic':tc.text,
                'ids':['7881302871304371',//yuna
                  '7881302089909614'//jim
                  // '7881300822021046'//big poppa
                ],
              }));
          if(roomRes.statusCode==200){
            final crmRes=await Future.wait([
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
      TextEditingController tc,List<String>nameKeys)=>
      Flexible(child: DropdownSearch(
    popupProps: PopupProps.dialog(showSearchBox: true),
    clearButtonProps: ClearButtonProps(isVisible: selected.value!=null),
    items: items,selectedItem: selected.value,
    itemAsString: (md)=>[...nameKeys, 'Wechat_Group_Name', 'Wechat_Alias']
        .map((e) => md[e]).join(' '),
    dropdownDecoratorProps: const DropDownDecoratorProps(
      dropdownSearchDecoration: InputDecoration(labelText: "Link with CRM MdMen"),
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
