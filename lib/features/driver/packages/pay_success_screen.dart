import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class PaySuccessScreen extends StatefulWidget {
  const PaySuccessScreen({super.key});
  @override State<PaySuccessScreen> createState() => _PaySuccessScreenState();
}
class _PaySuccessScreenState extends State<PaySuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState(){super.initState();_c=AnimationController(vsync:this,duration:700.ms);
    _s=Tween(begin:0.0,end:1.0).animate(CurvedAnimation(parent:_c,curve:Curves.elasticOut));_c.forward();}
  @override void dispose(){_c.dispose();super.dispose();}
  PackageModel _selectedPackage(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    return AppData.i.packages.firstWhere((p) => p.id == id, orElse: () => AppData.i.packages.first);
  }

  @override Widget build(BuildContext context) {
    final pkg = _selectedPackage(context);
    return Scaffold(backgroundColor:AC.bg,
    body:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:40),
      child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        AnimatedBuilder(animation:_c,builder:(_,__)=>Transform.scale(scale:_s.value,
          child:Container(width:120,height:120,decoration:BoxDecoration(gradient:AC.goldGrad,shape:BoxShape.circle,
            boxShadow:[BoxShadow(color:AC.gold.withOpacity(0.55),blurRadius:44,spreadRadius:4)]),
            child:const Icon(Icons.workspace_premium_rounded,color:AC.bg,size:60)))),
        const SizedBox(height:28),
        Text("You're ${pkg.name}!",style:const TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AC.t1))
          .animate().fadeIn(delay:400.ms),
        const SizedBox(height:10),
        Text('Welcome to Salahny ${pkg.name}. Your ${pkg.duration} plan is now active.',
          textAlign:TextAlign.center,style:const TextStyle(fontSize:14,color:AC.t3,height:1.6))
          .animate().fadeIn(delay:500.ms),
        const SizedBox(height:40),
        AppBtn(label:'Start Using Salahny',gold:true,
          onTap:()=>Navigator.pushNamedAndRemoveUntil(context,R.home,(_)=>false))
          .animate().fadeIn(delay:600.ms),
      ]))));
  }
}
