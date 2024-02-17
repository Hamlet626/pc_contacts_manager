import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc=useTextEditingController();
    final loading=useState(false);

    return Scaffold(body: Column(children: [
      Text('Please enter password',style: Theme.of(context).textTheme.headlineMedium,),
      TextField(controller: tc,),
      FilledButton(onPressed: loading.value?null:()async{
        loading.value=true;
        try{
          final r=await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: 'wenjian@patriotconceptions.com',
            password: tc.text);
        }catch(e){
          loading.value=false;}
      }, child: Text('Confirm'))
    ],),);
  }
}
