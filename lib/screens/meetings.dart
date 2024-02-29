import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/providers.dart';

class MeetingAdder extends HookConsumerWidget {
  final Map<String,dynamic>? gc;
  final Map<String,dynamic>? group;
  const MeetingAdder({this.gc, this.group, super.key});

  static show(BuildContext context,{Map<String,dynamic>? gc,Map<String,dynamic>? group})=>
      showModalBottomSheet(context: context, builder: (context)=>MeetingAdder(gc: gc, group: group,));
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final f=useMemoized(() => GlobalKey<FormBuilderState>());

    final gcs=ref.watch(gCsProvider).value??[];
    final groups=ref.watch(wcGroupsProvider).value??[];

    final selectedGC=useState<String?>(gc?['id']);
    final portalGCId=selectedGC.value==null?null:useFuture(useMemoized(
            () => FirebaseFirestore.instance.collection('u').where('rid',isEqualTo: selectedGC.value).get().then((v){
              if(v.size==0)throw 'GC not found on Portal, contact Hamlet with: rid:${selectedGC.value}';
              f.currentState?.patchValue({'title':"${v.docs[0].data()['name']}'s Match Meeting"});
              return v.docs[0].id;
            }),[selectedGC.value]));

    final loading=useState(false);


    return BottomSheet(onClosing: (){}, builder: (context)=>FormBuilder(
        key:f,
        initialValue: {
          if(gc!=null)'to':gc,
          if(group!=null)'wechat_group':group
        },
        child: Column(children: [
          DropDownSearchField(name: 'to', label: 'label', items: gcs,
            itemAsString: (gc)=>'${gc['First_Name']} ${gc['Last_Name']}',),

          if(portalGCId!=null)portalGCId.hasError?Text('${portalGCId.error}'):
          portalGCId.hasData?Container():const LinearProgressIndicator(),

          Divider(),
          FormBuilderTextField(name: 'title',
            validator: (v)=>v==null?'Please select a value':null,
            decoration:const InputDecoration(labelText: 'Title (show GC'),),

          DropDownSearchField(name: 'wechat_group', label: 'Wechat Group', items: groups,
            itemAsString: (group)=>group['topic'],),
          FormBuilderDateTimePicker(name: 'start',
            decoration:const InputDecoration(labelText: 'Start Time (show GC'),
            validator: (v)=>v==null?'Please select a value':null,),
          FormBuilderTextField(name: 'description',
            decoration:const InputDecoration(labelText: 'Description (show GC'),
            maxLines: 3,),

          TextButton(onPressed: loading.value||portalGCId?.data==null?null:(){
            if(!f.currentState!.saveAndValidate()||portalGCId?.data==null)return;
            loading.value=true;
            final data=f.currentState!.value;
            FirebaseFirestore.instance.collection('/classes/m/data').add({
              ...data,
              'to':portalGCId!.data,
              'wechat_group':data['wechat_group']['topic'],
              'type':2, 'stage':0
            });
            }, child: const Text('Create'))
        ],)));
  }
}


class DropDownSearchField<T> extends StatelessWidget {
  final String name;
  final String Function(T)? itemAsString;
  final String label;
  final Widget Function(BuildContext,T?)? dropdownBuilder;
  final void Function(T?)? onChanged;
  final List<T> items;

  const DropDownSearchField({super.key, required this.name, this.itemAsString, required this.label, this.dropdownBuilder, required this.items, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(builder: (field)=>DropdownSearch<T>(
      // validator: field.,
      selectedItem:field.value,
      popupProps: const PopupProps.dialog(showSearchBox: true),
      clearButtonProps: ClearButtonProps(isVisible: field.value!=null),
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(labelText: label),
      ),
      dropdownBuilder: dropdownBuilder,
      onChanged: (v){field.didChange(v);
        if(onChanged!=null)onChanged!(v);},
    ), name: name, validator: (v)=>v==null?'Please select a value':null,);
  }
}
