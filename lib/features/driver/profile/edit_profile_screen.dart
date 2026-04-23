import 'package:flutter/material.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  late final u = AppData.i.currentUser;
  final _fk = GlobalKey<FormState>();
  late final _name = TextEditingController(text:u.name);
  late final _phone = TextEditingController(text:u.phone);
  late final _email = TextEditingController(text:u.email);
  @override void dispose(){_name.dispose();_phone.dispose();_email.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'Edit Profile'),
    body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Form(key:_fk, child:Column(children:[
      const SizedBox(height:16),
      Center(child:Stack(children:[
        Container(width:88,height:88,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
          boxShadow:[BoxShadow(color:AC.red.withOpacity(0.4),blurRadius:22)]),
          child:Center(child:Text(u.name[0],style:const TextStyle(fontSize:38,fontWeight:FontWeight.w800,color:Colors.white)))),
        Positioned(bottom:0,right:0,child:Container(width:26,height:26,decoration:BoxDecoration(gradient:AC.goldGrad,shape:BoxShape.circle),
          child:const Icon(Icons.camera_alt_rounded,color:AC.bg,size:13))),
      ])),
      const SizedBox(height:32),
      AppField(label:'Full Name',hint:'',ctrl:_name,
        validator:(v)=>(v?.trim().isEmpty??true)?'Enter your name':null),
      const SizedBox(height:16),
      AppField(label:'Phone Number',hint:'',ctrl:_phone,keyboard:TextInputType.phone,
        validator:(v)=>(v??'').replaceAll(RegExp(r'\D'),'').length==11?null:'Phone must be 11 numbers'),
      const SizedBox(height:16),
      AppField(label:'Email Address',hint:'',ctrl:_email,keyboard:TextInputType.emailAddress,
        validator:(v)=>RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v??'').trim())?null:'Enter a valid email'),
      const SizedBox(height:32),
      AppBtn(label:'Save Changes',gold:true,onTap:() async {
        if(!_fk.currentState!.validate()) return;
        final ok = await AppErrorHandler.guard<bool>(
          context,
          () async {
            await MockData.saveCurrentUser(
              name:_name.text.trim(),
              phone:_phone.text.replaceAll(RegExp(r'\D'),''),
              email:_email.text.trim(),
            );
            return true;
          },
          fallbackMessage: 'Could not save your profile changes.',
          successMessage: 'Profile updated successfully',
        );
        if(context.mounted && ok == true) Navigator.pop(context);
      }),
      const SizedBox(height:32),
    ]))));
}
