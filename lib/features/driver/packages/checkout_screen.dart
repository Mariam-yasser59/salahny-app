import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override State<CheckoutScreen> createState() => _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  int _method = 0; bool _loading = false;
  static const _methods = [('💳','Credit / Debit Card'),('📱','Apple Pay'),('🏦','Bank Transfer')];
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'Checkout'),
    body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:8),
      ACard(glow:true,glowColor:AC.gold,child:Column(children:[
        const Row(children:[GoldBadge('Premium Plan'),Spacer(),Text('\$79',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:AC.gold))]),
        const SizedBox(height:6),
        const Text('3 months • Best for families',style:TextStyle(fontSize:13,color:AC.t3)),
        const SizedBox(height:12),const Div(),const SizedBox(height:12),
        InfoRow(label:'Subtotal',value:'\$79.00'),
        const SizedBox(height:8),
        InfoRow(label:'Discount',value:'-\$50.00'),
        const SizedBox(height:12),const Div(),const SizedBox(height:12),
        InfoRow(label:'Total',value:'\$79.00',bold:true),
      ])).animate().fadeIn(duration:400.ms),
      const SizedBox(height:24),
      const SecHeader(title:'Payment Method'),const SizedBox(height:12),
      ..._methods.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),
        child:GestureDetector(onTap:()=>setState(()=>_method=e.key),
          child:AnimatedContainer(duration:250.ms,padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(
              gradient:_method==e.key?LinearGradient(colors:[AC.red.withOpacity(0.14),AC.red.withOpacity(0.04)]):null,
              color:_method!=e.key?AC.s2:null,
              borderRadius:Rd.lgA,
              border:Border.all(color:_method==e.key?AC.red:AC.border,width:_method==e.key?1.5:0.8)),
            child:Row(children:[
              Text(e.value.$1,style:const TextStyle(fontSize:26)),const SizedBox(width:14),
              Text(e.value.$2,style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:_method==e.key?AC.t1:AC.t2)),
              const Spacer(),
              AnimatedContainer(duration:250.ms,width:22,height:22,
                decoration:BoxDecoration(shape:BoxShape.circle,color:_method==e.key?AC.red:Colors.transparent,
                  border:Border.all(color:_method==e.key?AC.red:AC.border2,width:2)),
                child:_method==e.key?const Icon(Icons.check_rounded,color:Colors.white,size:13):null),
            ])))).animate().fadeIn(delay:((e.key+1)*100).ms)),
      const SizedBox(height:24),
      AppBtn(label:'Pay Now',gold:true,loading:_loading,onTap:() async {
        setState(()=>_loading=true);
        await Future.delayed(1500.ms);
        if(mounted){setState(()=>_loading=false);Navigator.pushReplacementNamed(context,R.paySuccess);}
      }).animate().fadeIn(delay:500.ms),
      const SizedBox(height:24),
    ])),
  );
}
