import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});
  static const _types = [
    ('🔋','Dead Battery','Jumpstart within 20 min',AC.warning),
    ('🛞','Flat Tire','Tire change on the spot',AC.info),
    ('⛽','Out of Fuel','Emergency fuel delivery',AC.success),
    ('🔑','Lockout','Fast access recovery',AC.error),
    ('🚗','Breakdown','Full tow to workshop',AC.red),
    ('🔥','Overheating','Coolant & diagnosis',AC.warning),
  ];
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'Emergency Help'),
    body:Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:8),
      Container(padding:const EdgeInsets.all(18),
        decoration:BoxDecoration(gradient:LinearGradient(colors:[AC.error.withOpacity(0.2),AC.bg]),
          borderRadius:Rd.lgA,border:Border.all(color:AC.error.withOpacity(0.3))),
        child:Row(children:[
          PulseRing(color:AC.error,size:60,
            child:Container(width:40,height:40,decoration:BoxDecoration(color:AC.error,shape:BoxShape.circle),
              child:const Icon(Icons.emergency_share_rounded,color:Colors.white,size:20))),
          const SizedBox(width:16),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Instant Emergency Response',style:TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:AC.t1)),
            const Text('Technician dispatched to your location',style:TextStyle(fontSize:12,color:AC.t3)),
            const SizedBox(height:4),
            Row(children:[Container(width:7,height:7,decoration:const BoxDecoration(color:AC.success,shape:BoxShape.circle)),
              const SizedBox(width:6),const Text('Available 24/7',style:TextStyle(fontSize:11,color:AC.success))]),
          ])),
        ])).animate().fadeIn(duration:400.ms),
      const SizedBox(height:20),
      const Align(alignment:Alignment.centerLeft,child:Text('What happened?',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AC.t1))),
      const SizedBox(height:14),
      Expanded(child:GridView.count(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.2,
        children:_types.map((t)=>GestureDetector(onTap:()=>Navigator.pushNamed(context,R.bookService),
          child:Container(padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(
              gradient:LinearGradient(colors:[t.$4.withOpacity(0.16),t.$4.withOpacity(0.04)]),
              borderRadius:Rd.lgA,
              border:Border.all(color:t.$4.withOpacity(0.3),width:0.8)),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(t.$1,style:const TextStyle(fontSize:28)),
              const Spacer(),
              Text(t.$2,style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:t.$4)),
              Text(t.$3,style:const TextStyle(fontSize:11,color:AC.t3)),
            ])).animate().fadeIn(delay:(_types.indexOf(t)*80).ms))).toList())),
    ])));
}
