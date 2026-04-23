import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class WorkshopsScreen extends StatelessWidget {
  const WorkshopsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'Nearby Workshops'),
    body:Column(children:[
      // Map placeholder
      Container(height:220,margin:const EdgeInsets.fromLTRB(24,8,24,0),
        decoration:BoxDecoration(borderRadius:Rd.lgA,gradient:const LinearGradient(colors:[Color(0xFF1A1A1A),Color(0xFF141414)])),
        child:Stack(children:[
          Positioned.fill(child:ClipRRect(borderRadius:Rd.lgA,child:CustomPaint(painter:_MapPaint()))),
          Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
            Container(width:48,height:48,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
              boxShadow:[BoxShadow(color:AC.red.withOpacity(0.5),blurRadius:20)]),
              child:const Icon(Icons.my_location_rounded,color:Colors.white,size:24)),
            const SizedBox(height:8),
            const Text('Your Location',style:TextStyle(fontSize:12,color:AC.t2)),
          ])),
        ])),
      const SizedBox(height:16),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),
        child:SecHeader(title:'Available Now',sub:'${AppData.i.workshops.length} workshops within 10 miles')),
      const SizedBox(height:12),
      Expanded(child:ListView.separated(padding:const EdgeInsets.fromLTRB(24,0,24,24),
        itemCount:AppData.i.workshops.length,separatorBuilder:(_,__)=>const SizedBox(height:12),
        itemBuilder:(_,i){final w=AppData.i.workshops[i];
          return ACard(onTap:()=>Navigator.pushNamed(context,R.workshopDetail,arguments:w.id),
            padding:const EdgeInsets.all(16),child:Row(children:[
              Container(width:52,height:52,decoration:BoxDecoration(gradient:AC.redGrad,borderRadius:Rd.mdA),
                child:const Icon(Icons.garage_rounded,color:Colors.white,size:26)),
              const SizedBox(width:14),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[Expanded(child:Text(w.name,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AC.t1))),if(w.isVerified) const GoldBadge('Verified')]),
                const SizedBox(height:3),
                Text(w.specialty,style:const TextStyle(fontSize:12,color:AC.t3)),
                const SizedBox(height:6),
                Row(children:[RatingStars(rating:w.rating),const SizedBox(width:5),Text(w.address,style:const TextStyle(fontSize:11,color:AC.t3))]),
              ])),
              Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
                  decoration:BoxDecoration(
                    color:w.isOpen?AC.success.withOpacity(0.12):AC.error.withOpacity(0.12),borderRadius:Rd.fullA,
                    border:Border.all(color:w.isOpen?AC.success.withOpacity(0.4):AC.error.withOpacity(0.4))),
                  child:Text(w.isOpen?'Open':'Closed',style:TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:w.isOpen?AC.success:AC.error))),
                const SizedBox(height:6),
                Text('${w.distance} mi',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:AC.t2)),
              ]),
            ]));
        })),
    ]),
  );
}
class _MapPaint extends CustomPainter {
  @override void paint(Canvas c,Size s){
    final g=Paint()..color=const Color(0xFF2A2A2A)..strokeWidth=0.5;
    for(double x=0;x<s.width;x+=24) c.drawLine(Offset(x,0),Offset(x,s.height),g);
    for(double y=0;y<s.height;y+=24) c.drawLine(Offset(0,y),Offset(s.width,y),g);
    final r=Paint()..color=const Color(0xFF333333)..strokeWidth=8..strokeCap=StrokeCap.round;
    c.drawLine(Offset(0,s.height*0.5),Offset(s.width,s.height*0.5),r);
    c.drawLine(Offset(s.width*0.4,0),Offset(s.width*0.4,s.height),r);
  }
  @override bool shouldRepaint(_)=>false;
}
