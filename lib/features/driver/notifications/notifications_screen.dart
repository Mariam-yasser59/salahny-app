import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'Notifications'),
    body:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24,vertical:14),
      itemCount:MockData.notifications.length,separatorBuilder:(_,__)=>const SizedBox(height:10),
      itemBuilder:(_,i){
        final n=MockData.notifications[i];
        final iconMap={'booking':Icons.calendar_today_rounded,'reminder':Icons.notifications_active_outlined,'promo':Icons.local_offer_outlined};
        final colorMap={'booking':AC.info,'reminder':AC.warning,'promo':AC.gold};
        final col=colorMap[n.type]??AC.info;
        return Container(padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(
            color:n.isRead?AC.s2:AC.red.withOpacity(0.05),borderRadius:Rd.lgA,
            border:Border.all(color:n.isRead?AC.border:AC.red.withOpacity(0.2),width:0.8)),
          child:Row(children:[
            Container(width:44,height:44,decoration:BoxDecoration(color:col.withOpacity(0.12),borderRadius:Rd.mdA),
              child:Icon(iconMap[n.type]??Icons.notifications_outlined,color:col,size:20)),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(n.title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:AC.t1)),
              const SizedBox(height:2),
              Text(n.body,style:const TextStyle(fontSize:12,color:AC.t3,height:1.4),maxLines:2),
            ])),
            if(!n.isRead) Container(width:8,height:8,decoration:const BoxDecoration(color:AC.red,shape:BoxShape.circle)),
          ])).animate().fadeIn(delay:(i*80).ms);
      }),
  );
}
