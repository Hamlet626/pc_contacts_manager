import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

const teams={
  'Sunny':{'4301724000088196055','4301724000088225004','4301724000091251001',
    '4301724000099798015','4301724000103540001','4301724000122984001','4301724000123199001'},
  'Sobeida':{'4301724000010400003','4301724000028185003','4301724000088460001',
    '4301724000089025005','4301724000093428018','4301724000106615003','4301724000113947001'},
  'Rachel':{'4301724000103540001','4301724000118792001','4301724000118792003',
    '4301724000122978001','4301724000122989001'}
};

@Riverpod(keepAlive: true)
Future<List<Map<String,dynamic>>>GCs(GCsRef ref)async{
  final data = await getZoho("select First_Name, Last_Name, Match_Grade, On_Hold_By, Recruiter from Leads where (Lead_Status = 'Matching')");
  return (data['data'].cast<Map<String,dynamic>>() as List<Map<String,dynamic>>).map((gcRec){
    final teamN=teams.entries.where((e) => e.value.contains(gcRec['Recruiter']?['id']));
    return {...gcRec,'team':teamN.isEmpty?'unknown':teamN.first.key};
  }).toList();
}

@Riverpod(keepAlive: true)
Future<List<Map<String,dynamic>>>IPs(IPsRef ref)async{
  final data = await getZoho('select First_Name, Last_Name, Wechat_Group_Name, Wechat_Alias from Intended_Parents where (Wechat_Group_Name is not null)');
  return data['data'].cast<Map<String,dynamic>>();
}

@Riverpod(keepAlive: true)
Future<List<Map<String,dynamic>>>middleMen(MiddleMenRef ref)async{
  final data = await getZoho('select Name, Wechat_Group_Name, Wechat_Alias from MiddleMen where (Wechat_Group_Name is not null)');
  return data['data'].cast<Map<String,dynamic>>();
}

@Riverpod(keepAlive: true)
Future<List<Map<String,dynamic>>>wcGroups(WcGroupsRef ref)async{
  final res = await post(Uri.parse('https://pcbackend-egozmxid3q-uw.a.run.app/wct/findRoom'),
  headers: {'wcKey':'hamlet'});
  print(res.body);
  if(res.statusCode==240)throw "user not logged in";
  return json.decode(res.body).cast<Map<String,dynamic>>();
}

@Riverpod(keepAlive: true)
Stream<bool> auth(AuthRef ref)=>FirebaseAuth.instance.authStateChanges().map((event) => event?.uid=='CN5MXKClciZboPx4mFbzW1UjxC53');

@Riverpod()
Stream<QuerySnapshot<Map<String,dynamic>>> disburseData(DisburseDataRef ref)async*{
  final authed=ref.watch(authProvider).value;
  if(authed!=true)return;
  ref.keepAlive();
  yield* FirebaseFirestore.instance.collection('zoho ext').snapshots();
}


getZoho(String query)async{
  final r = json.decode(utf8.decode((
      await post(
          Uri.parse('https://us-central1-pc-application-portal.cloudfunctions.net/zohoAPI'),
          headers: {'cKey': 'hamlet','Content-Type': 'application/json'},
          body: json.encode({
            'url':'https://www.zohoapis.com/crm/v3/coql',
            'data':{"select_query" :query}
          }))).bodyBytes));
  if(r['data']==null)throw r;
  return r['data'];
}
