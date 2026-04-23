import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override State<OtpScreen> createState() => _OtpScreenState();
}
class _OtpScreenState extends State<OtpScreen> {
  final _ctrls = List.generate(4, (_) => TextEditingController());
  final _focuses = List.generate(4, (_) => FocusNode());
  int _secs = 59; bool _loading = false;

  @override void initState() { super.initState(); _startTimer(); }
  void _startTimer() async {
    while(_secs>0&&mounted){ await Future.delayed(1000.ms); if(mounted) setState(()=>_secs--); }
  }
  @override void dispose() { for(final c in _ctrls) c.dispose(); for(final f in _focuses) f.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final phone = AppData.i.currentUser.phone;

    return Scaffold(
    backgroundColor:AC.bg,
    body:SafeArea(child:Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:16),
      Align(alignment:Alignment.centerLeft,
        child:GestureDetector(onTap:()=>Navigator.pop(context),
          child:Container(width:42,height:42,decoration:BoxDecoration(color:AC.s2,borderRadius:Rd.mdA,border:Border.all(color:AC.border)),
            child:const Icon(Icons.arrow_back_ios_new_rounded,color:AC.t1,size:18)))),
      const SizedBox(height:56),
      Container(width:80,height:80,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
        boxShadow:[BoxShadow(color:AC.red.withOpacity(0.45),blurRadius:28)]),
        child:const Icon(Icons.message_outlined,color:Colors.white,size:36))
        .animate().scale(begin:const Offset(0,0),duration:600.ms,curve:Curves.elasticOut),
      const SizedBox(height:28),
      const Text('Verify Your Number',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800,color:AC.t1))
        .animate().fadeIn(delay:200.ms),
      const SizedBox(height:8),
      Text('Enter the 4-digit code sent to\n$phone',textAlign:TextAlign.center,
        style:const TextStyle(fontSize:14,color:AC.t3,height:1.6)).animate().fadeIn(delay:300.ms),
      const SizedBox(height:44),
      Row(mainAxisAlignment:MainAxisAlignment.center, children:List.generate(4,(i)=>Container(
        margin:const EdgeInsets.symmetric(horizontal:8), width:62, height:66,
        decoration:BoxDecoration(color:AC.s2, borderRadius:Rd.mdA,
          border:Border.all(color:_focuses[i].hasFocus?AC.red:AC.border, width:_focuses[i].hasFocus?1.5:0.8)),
        child:TextField(controller:_ctrls[i], focusNode:_focuses[i],
          textAlign:TextAlign.center, keyboardType:TextInputType.number, maxLength:1,
          style:const TextStyle(fontSize:24,fontWeight:FontWeight.w700,color:AC.t1),
          decoration:const InputDecoration(counterText:'',border:InputBorder.none,contentPadding:EdgeInsets.zero),
          onChanged:(v){if(v.isNotEmpty&&i<3) FocusScope.of(context).requestFocus(_focuses[i+1]);
            if(v.isEmpty&&i>0) FocusScope.of(context).requestFocus(_focuses[i-1]);
            setState((){});},
        )))).animate().fadeIn(delay:400.ms),
      const SizedBox(height:36),
      AppBtn(label:'Verify & Continue',loading:_loading,onTap:() async {
        final code = _ctrls.map((c) => c.text.trim()).join();
        if(code.length != 4){
          AppErrorHandler.showMessage(context, 'Enter the 4-digit verification code');
          return;
        }
        setState(()=>_loading=true);
        final role = await AppErrorHandler.guard<String?>(
          context,
          () async {
            await Future.delayed(1200.ms);
            await MockData.saveToken('tok_${DateTime.now().millisecondsSinceEpoch}');
            return MockData.getRole();
          },
          fallbackMessage: 'Could not verify the code. Please try again.',
        );
        if(!mounted) return;
        setState(()=>_loading=false);
        if(role != null){
          Navigator.pushNamedAndRemoveUntil(context,role=='workshop'?R.wsDashboard:R.home,(_)=>false);
        }
      }).animate().fadeIn(delay:500.ms),
      const SizedBox(height:24),
      Row(mainAxisAlignment:MainAxisAlignment.center,children:[
        Text(_secs>0?'Resend code in 0:${_secs.toString().padLeft(2,'0')}':'',
          style:const TextStyle(fontSize:13,color:AC.t3)),
        if(_secs==0) GestureDetector(onTap:(){setState(()=>_secs=59);_startTimer();},
          child:const Text('Resend Code',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:AC.red))),
      ]).animate().fadeIn(delay:600.ms),
    ]))),
  );
  }
}
