import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _fk=GlobalKey<FormState>();
  final _name=TextEditingController(); final _email=TextEditingController();
  final _phone=TextEditingController(); final _pass=TextEditingController();
  bool _loading=false;
  String? _validateName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your name';
    if (value.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (value.isEmpty) return 'Enter email';
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter phone';
    if (digits.length != 11) return 'Phone must be 11 numbers';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add one uppercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Add one number';
    return null;
  }

  @override void dispose(){ _name.dispose();_email.dispose();_phone.dispose();_pass.dispose();super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:SafeArea(child:SingleChildScrollView(
      padding:const EdgeInsets.symmetric(horizontal:24),
      child:Form(key:_fk,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const SizedBox(height:16),
        GestureDetector(onTap:()=>Navigator.pop(context),
          child:Container(width:42,height:42,decoration:BoxDecoration(color:AC.s2,borderRadius:Rd.mdA,border:Border.all(color:AC.border)),
            child:const Icon(Icons.arrow_back_ios_new_rounded,color:AC.t1,size:18))),
        const SizedBox(height:32),
        const Text('Create Account',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800,color:AC.t1))
          .animate().fadeIn(duration:400.ms),
        const SizedBox(height:8),
        const Text('Join 50,000+ satisfied drivers',style:TextStyle(fontSize:14,color:AC.t3))
          .animate().fadeIn(delay:150.ms),
        const SizedBox(height:36),
        ...[ AppField(label:'Full Name',hint:'John Smith',ctrl:_name,
            validator:_validateName),
          const SizedBox(height:16),
          AppField(label:'Email Address',hint:'you@example.com',ctrl:_email,keyboard:TextInputType.emailAddress,
            validator:_validateEmail),
          const SizedBox(height:16),
          AppField(label:'Phone Number',hint:'01012345678',ctrl:_phone,keyboard:TextInputType.phone,
            validator:_validatePhone),
          const SizedBox(height:16),
          AppField(label:'Password',hint:'At least 8 characters',ctrl:_pass,obscure:true,
            validator:_validatePassword),
        ].asMap().entries.map((e)=>e.value.runtimeType==SizedBox?e.value:
          (e.value as Widget).animate().fadeIn(delay:(200+e.key*50).ms).slideY(begin:0.2,end:0)),
        const SizedBox(height:32),
        AppBtn(label:'Create Account',loading:_loading,onTap:() async {
          if(!_fk.currentState!.validate()) return;
          setState(()=>_loading=true);
          final ok = await AppErrorHandler.guard<bool>(
            context,
            () async {
              await MockData.saveCurrentUser(
                name: _name.text.trim(),
                phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
                email: _email.text.trim(),
              );
              await MockData.saveToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
              await Future.delayed(1200.ms);
              return true;
            },
            fallbackMessage: 'Could not create the account. Please try again.',
          );
          if(!mounted) return;
          setState(()=>_loading=false);
          if(ok == true) Navigator.pushNamed(context,R.otp);
        }).animate().fadeIn(delay:500.ms),
        const SizedBox(height:20),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          const Text('Already have an account? ',style:TextStyle(fontSize:13,color:AC.t3)),
          GestureDetector(onTap:()=>Navigator.pop(context),
            child:const Text('Sign In',style:TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:AC.red))),
        ]).animate().fadeIn(delay:550.ms),
        const SizedBox(height:32),
      ])))),
  );
}
