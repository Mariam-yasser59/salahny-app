import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});
  @override State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}
class _BookingConfirmScreenState extends State<BookingConfirmScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale, _fade;
  @override void initState(){super.initState();
    _c=AnimationController(vsync:this,duration:700.ms);
    _scale=Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_c,curve:Curves.elasticOut));
    _fade=Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_c,curve:const Interval(0,0.5)));
    _c.forward();}
  @override void dispose(){_c.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:24),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        AnimatedBuilder(animation:_c,builder:(_,__)=>FadeTransition(opacity:_fade,
          child:Transform.scale(scale:_scale.value,
            child:Container(width:110,height:110,
              decoration:BoxDecoration(gradient:LinearGradient(colors:[AC.success.withOpacity(0.8),AC.success]),
                shape:BoxShape.circle,boxShadow:[BoxShadow(color:AC.success.withOpacity(0.55),blurRadius:44,spreadRadius:4)]),
              child:const Icon(Icons.check_rounded,color:Colors.white,size:56))))),
        const SizedBox(height:32),
        const Text('Booking Confirmed! 🎉',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AC.t1))
          .animate().fadeIn(delay:400.ms),
        const SizedBox(height:10),
        const Text("We'll confirm your booking within minutes. You'll receive a notification shortly.",
          textAlign:TextAlign.center,style:TextStyle(fontSize:14,color:AC.t3,height:1.6))
          .animate().fadeIn(delay:500.ms),
        const SizedBox(height:32),
        ACard(glow:true,glowColor:AC.success,child:Column(children:[
          InfoRow(label:'Service',value:'Oil Change'),
          const SizedBox(height:12),
          InfoRow(label:'Workshop',value:'ProTech Auto Center'),
          const SizedBox(height:12),
          InfoRow(label:'Date & Time',value:'Dec 22 • 10:00 AM'),
          const SizedBox(height:12),
          InfoRow(label:'Vehicle',value:'Toyota Camry 2022'),
          const SizedBox(height:12),const Div(),const SizedBox(height:12),
          InfoRow(label:'Total',value:'\$89.00',bold:true),
        ])).animate().fadeIn(delay:600.ms),
        const SizedBox(height:28),
        AppBtn(label:'Track Booking',
          onTap:()=>Navigator.pushReplacementNamed(context,R.bookingTrack),
          icon:const Icon(Icons.location_on_rounded,color:Colors.white,size:18))
          .animate().fadeIn(delay:700.ms),
        const SizedBox(height:12),
        AppBtn(label:'Back to Home',outline:true,
          onTap:()=>Navigator.pushReplacementNamed(context,R.home))
          .animate().fadeIn(delay:750.ms),
      ]))),
  );
}
