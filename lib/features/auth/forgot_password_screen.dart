import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl=TextEditingController(); bool _sent=false, _loading=false;
  @override void dispose(){ _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:16),
      Align(alignment:Alignment.centerLeft, child:GestureDetector(onTap:()=>Navigator.pop(context),
        child:Container(width:42,height:42,decoration:BoxDecoration(color:AC.s2,borderRadius:Rd.mdA,border:Border.all(color:AC.border)),
          child:const Icon(Icons.arrow_back_ios_new_rounded,color:AC.t1,size:18)))),
      const SizedBox(height:60),
      if(!_sent)...[
        Container(width:80,height:80,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle),
          child:const Icon(Icons.lock_reset_rounded,color:Colors.white,size:36))
          .animate().scale(begin:const Offset(0,0),duration:600.ms,curve:Curves.elasticOut),
        const SizedBox(height:28),
        const Text('Reset Password',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AC.t1)),
        const SizedBox(height:8),
        const Text('Enter your email and we\'ll send you\na reset link',textAlign:TextAlign.center,
          style:TextStyle(fontSize:14,color:AC.t3,height:1.6)),
        const SizedBox(height:40),
        AppField(label:'Email Address',hint:'you@example.com',ctrl:_ctrl,keyboard:TextInputType.emailAddress),
        const SizedBox(height:28),
        AppBtn(label:'Send Reset Link',loading:_loading,onTap:() async {
          setState(()=>_loading=true);
          await Future.delayed(1200.ms);
          if(mounted) setState((){_loading=false;_sent=true;});
        }),
      ] else ...[
        Container(width:80,height:80,decoration:BoxDecoration(color:AC.success.withOpacity(0.12),shape:BoxShape.circle,
          border:Border.all(color:AC.success.withOpacity(0.4))),
          child:const Icon(Icons.mark_email_read_outlined,color:AC.success,size:36))
          .animate().scale(begin:const Offset(0,0),duration:600.ms,curve:Curves.elasticOut),
        const SizedBox(height:28),
        const Text('Check Your Email',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AC.t1)),
        const SizedBox(height:8),
        const Text('We\'ve sent a password reset link.\nCheck your inbox.',textAlign:TextAlign.center,
          style:TextStyle(fontSize:14,color:AC.t3,height:1.6)),
        const SizedBox(height:40),
        AppBtn(label:'Back to Login',onTap:()=>Navigator.pushReplacementNamed(context,R.login)),
      ],
    ]))),
  );
}
