import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'Privacy Policy'),
    body:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('Privacy Policy',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AC.t1)),
      const SizedBox(height:16),
      ...['1. Data We Collect','2. How We Use Your Data','3. Data Sharing','4. Your Rights','5. Contact Us']
        .map((s)=>Padding(padding:const EdgeInsets.only(bottom:16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(s,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w700,color:AC.t1)),
          const SizedBox(height:6),
          const Text('We take your privacy seriously and are committed to protecting your personal data in accordance with international data protection standards.',
            style:TextStyle(fontSize:14,color:AC.t3,height:1.6)),
        ]))),
    ])));
}
