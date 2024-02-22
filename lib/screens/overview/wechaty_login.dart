import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart';
import 'package:pc_wechat_manager/providers/providers.dart';
import 'package:url_launcher/url_launcher_string.dart';

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