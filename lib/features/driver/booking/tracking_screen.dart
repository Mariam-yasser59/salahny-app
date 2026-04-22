import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});
  static const _steps = [
    ('Booking Confirmed','Your request was received',true,AC.success),
    ('Awaiting Workshop','Workshop is reviewing','true',AC.warning),
    ('Work in Progress','Technician has started','false',AC.info),
    ('Ready for Pickup','Your car is ready','false',AC.success),
  ];
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'Track Booking'),
    body:Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:8),
      ACard(glow:true,glowColor:AC.warning,child:Row(children:[
        Container(width:48,height:48,decoration:BoxDecoration(gradient:AC.redGrad,borderRadius:Rd.mdA)),
        const SizedBox(width:14),
        const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Oil Change',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AC.t1)),
          Text('ProTech Auto • Today 10:00 AM',style:TextStyle(fontSize:12,color:AC.t3)),
        ])),
        const StatusChip('Active'),
      ])).animate().fadeIn(duration:400.ms),
      const SizedBox(height:24),
      Expanded(child:ListView.builder(itemCount:_steps.length,itemBuilder:(_,i){
        final (title,sub,done,col)=_steps[i];
        final isDone = done=='true'||done==true.toString();
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Column(children:[
            Container(width:36,height:36,decoration:BoxDecoration(
              gradient:isDone?LinearGradient(colors:[col.withOpacity(0.8),col]):null,
              color:isDone?null:AC.s3,shape:BoxShape.circle,
              border:isDone?null:Border.all(color:AC.border)),
              child:Icon(isDone?Icons.check_rounded:Icons.radio_button_unchecked_rounded,
                color:isDone?Colors.white:AC.t4,size:18)),
            if(i<_steps.length-1) Container(width:2,height:52,color:isDone?col.withOpacity(0.4):AC.border),
          ]),
          const SizedBox(width:16),
          Expanded(child:Padding(padding:const EdgeInsets.only(bottom:18),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(title,style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:isDone?AC.t1:AC.t3)),
              Text(sub,style:const TextStyle(fontSize:12,color:AC.t3)),
            ]))),
        ]).animate().fadeIn(delay:(i*100).ms).slideX(begin:0.2,end:0,delay:(i*100).ms);
      })),
      Padding(padding:const EdgeInsets.only(bottom:32),
        child:AppBtn(label:'Chat with Mechanic',outline:true,
          onTap:()=>Navigator.pushNamed(context,R.mechanicChat),
          icon:const Icon(Icons.chat_bubble_outline_rounded,color:AC.red,size:18))),
    ])),
  );
}
