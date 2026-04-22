import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'Subscription Plans'),
    body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:12),
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:AC.redGrad,borderRadius:Rd.lgA,
        boxShadow:[BoxShadow(color:AC.red.withOpacity(0.4),blurRadius:24)]),
        child:Column(children:[
          const GoldBadge('Exclusive Deals',icon:Icons.local_offer_rounded),
          const SizedBox(height:12),
          const Text('Choose Your Plan',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:Colors.white)),
          const SizedBox(height:6),
          const Text('Save more, worry less with Salahny subscriptions',style:TextStyle(fontSize:13,color:Colors.white70)),
        ])).animate().fadeIn(duration:400.ms),
      const SizedBox(height:24),
      ...PackageModel.mockList.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:16),
        child:_PlanCard(pkg:e.value).animate().fadeIn(delay:((e.key+1)*100).ms).slideY(begin:0.2,end:0))),
      const SizedBox(height:20),
    ])),
  );
}

class _PlanCard extends StatelessWidget {
  final PackageModel pkg;
  const _PlanCard({required this.pkg});
  @override Widget build(BuildContext context) => Container(
    decoration:BoxDecoration(
      gradient:pkg.isPopular?LinearGradient(colors:[AC.redDark.withOpacity(0.35),AC.bg]):null,
      color:pkg.isPopular?null:AC.s2,
      borderRadius:Rd.lgA,
      border:Border.all(color:pkg.isPopular?AC.red:AC.border,width:pkg.isPopular?1.5:0.8),
      boxShadow:pkg.isPopular?[BoxShadow(color:AC.red.withOpacity(0.2),blurRadius:22)]:null),
    child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(pkg.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:AC.t1)),
          Text(pkg.tagline,style:const TextStyle(fontSize:12,color:AC.t3)),
        ])),
        if(pkg.isPopular) const GoldBadge('Most Popular'),
      ]),
      const SizedBox(height:14),
      Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        Text('\$${pkg.price.toInt()}',style:const TextStyle(fontSize:32,fontWeight:FontWeight.w900,color:AC.t1)),
        Padding(padding:const EdgeInsets.only(bottom:4),child:Text(' / ${pkg.duration}',style:const TextStyle(fontSize:13,color:AC.t3))),
        const Spacer(),
        if(pkg.originalPrice>pkg.price) Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
          decoration:BoxDecoration(color:AC.success.withOpacity(0.12),borderRadius:Rd.fullA,border:Border.all(color:AC.success.withOpacity(0.3))),
          child:Text('Save \$${(pkg.originalPrice-pkg.price).toInt()}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,color:AC.success))),
      ]),
      const SizedBox(height:14),const Div(),const SizedBox(height:14),
      ...pkg.features.map((f)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
        Container(width:20,height:20,decoration:BoxDecoration(gradient:AC.goldGrad,shape:BoxShape.circle),
          child:const Icon(Icons.check_rounded,size:12,color:AC.bg)),
        const SizedBox(width:10),
        Text(f,style:const TextStyle(fontSize:13,color:AC.t1)),
      ]))),
      const SizedBox(height:16),
      AppBtn(label:'Subscribe Now',gold:pkg.isPopular,
        onTap:()=>Navigator.pushNamed(context,R.checkout,arguments:pkg.id)),
    ])));
}
