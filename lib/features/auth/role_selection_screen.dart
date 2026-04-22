import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});
  @override State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}
class _RoleSelectionScreenState extends State<RoleSelectionScreen> with SingleTickerProviderStateMixin {
  String? _role;
  late AnimationController _bg;
  @override void initState() { super.initState(); _bg = AnimationController(vsync:this, duration:12000.ms)..repeat(); }
  @override void dispose() { _bg.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:Stack(children:[
      AnimatedBuilder(animation:_bg, builder:(_,__)=>Positioned(top:-120,right:-120,
        child:Transform.rotate(angle:_bg.value*6.28,
          child:Container(width:400,height:400,
            decoration:BoxDecoration(shape:BoxShape.circle,
              gradient:SweepGradient(colors:[AC.red.withOpacity(0.07),Colors.transparent,
                AC.gold.withOpacity(0.04),Colors.transparent,AC.red.withOpacity(0.07)])))))),

      SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:24),
        child:Column(children:[
          const SizedBox(height:40),
          ShaderMask(shaderCallback:(b)=>AC.redGrad.createShader(b),
            child:const Text('SALAHNY', style:TextStyle(fontSize:40,fontWeight:FontWeight.w800,color:Colors.white,letterSpacing:3)))
            .animate().fadeIn(duration:600.ms).slideY(begin:-0.3,end:0),
          const SizedBox(height:8),
          const Text('Choose your account type', style:TextStyle(fontSize:14,color:AC.t3))
            .animate().fadeIn(delay:200.ms),
          const SizedBox(height:48),

          _RoleCard(emoji:'🚗', title:'Vehicle Owner',
            sub:'Book services, track your car health, and get AI diagnostics',
            selected:_role=='driver', onTap:()=>setState(()=>_role='driver'))
            .animate().fadeIn(delay:300.ms).slideX(begin:0.3,end:0),
          const SizedBox(height:16),
          _RoleCard(emoji:'🔧', title:'Workshop / Garage',
            sub:'Manage requests, bookings, and grow your auto business',
            selected:_role=='workshop', onTap:()=>setState(()=>_role='workshop'))
            .animate().fadeIn(delay:450.ms).slideX(begin:0.3,end:0),

          const Spacer(),
          AnimatedOpacity(opacity:_role!=null?1:0.35, duration:250.ms,
            child:AppBtn(label:'Continue',
              onTap:_role!=null?()async{
                await MockData.saveRole(_role!);
                if(mounted) Navigator.pushNamed(context,R.login);
              }:null,
              icon:const Icon(Icons.arrow_forward_rounded,color:Colors.white,size:18))),
          const SizedBox(height:16),
          Row(mainAxisAlignment:MainAxisAlignment.center, children:[
            const Text("Don't have an account? ", style:TextStyle(fontSize:13,color:AC.t3)),
            GestureDetector(onTap:()=>Navigator.pushNamed(context,R.register),
              child:const Text('Sign Up', style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:AC.red))),
          ]),
          const SizedBox(height:32),
        ]))),
    ]),
  );
}

class _RoleCard extends StatelessWidget {
  final String emoji,title,sub; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.emoji,required this.title,required this.sub,required this.selected,required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap:onTap,
    child:AnimatedContainer(duration:250.ms,
      padding:const EdgeInsets.all(20),
      decoration:BoxDecoration(
        gradient:selected?LinearGradient(colors:[AC.red.withOpacity(0.18),AC.red.withOpacity(0.06)]):
          const LinearGradient(colors:[Color(0xFF1C1C1C),Color(0xFF161616)]),
        borderRadius:Rd.lgA,
        border:Border.all(color:selected?AC.red:AC.border, width:selected?1.5:0.8),
        boxShadow:selected?[BoxShadow(color:AC.red.withOpacity(0.22),blurRadius:20)]:null),
      child:Row(children:[
        AnimatedContainer(duration:250.ms, width:58,height:58,
          decoration:BoxDecoration(color:selected?AC.red.withOpacity(0.18):AC.s3, borderRadius:Rd.mdA),
          child:Center(child:Text(emoji,style:const TextStyle(fontSize:28)))),
        const SizedBox(width:16),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:TextStyle(fontSize:16,fontWeight:FontWeight.w700,
            color:selected?AC.t1:AC.t2)),
          const SizedBox(height:4),
          Text(sub,style:const TextStyle(fontSize:12,color:AC.t3,height:1.4)),
        ])),
        AnimatedContainer(duration:250.ms, width:22,height:22,
          decoration:BoxDecoration(shape:BoxShape.circle,
            color:selected?AC.red:Colors.transparent,
            border:Border.all(color:selected?AC.red:AC.border2,width:2)),
          child:selected?const Icon(Icons.check_rounded,color:Colors.white,size:13):null),
      ])));
}
