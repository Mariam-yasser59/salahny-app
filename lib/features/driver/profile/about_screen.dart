import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'About'),
    body:Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(width:96,height:96,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
        boxShadow:[BoxShadow(color:AC.red.withOpacity(0.45),blurRadius:32)]),
        child:const Center(child:Text('S',style:TextStyle(fontSize:44,fontWeight:FontWeight.w800,color:Colors.white)))),
      const SizedBox(height:20),
      const Text('SALAHNY',style:TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:AC.t1,letterSpacing:3)),
      const Text('Version 1.0.0',style:TextStyle(fontSize:13,color:AC.t3)),
      const SizedBox(height:16),
      const Text('Your Smart Auto Partner',style:TextStyle(fontSize:15,color:AC.t2)),
      const SizedBox(height:32),
      const GoldBadge('Made with ❤️ for drivers'),
    ]))));
}
