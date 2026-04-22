import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override State<EditProfileScreen> createState() => _EditProfileScreenState();
}
class _EditProfileScreenState extends State<EditProfileScreen> {
  static const u = UserModel.mock;
  late final _name = TextEditingController(text:u.name);
  late final _phone = TextEditingController(text:u.phone);
  late final _email = TextEditingController(text:u.email);
  @override void dispose(){_name.dispose();_phone.dispose();_email.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'Edit Profile'),
    body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:16),
      Center(child:Stack(children:[
        Container(width:88,height:88,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
          boxShadow:[BoxShadow(color:AC.red.withOpacity(0.4),blurRadius:22)]),
          child:Center(child:Text(u.name[0],style:const TextStyle(fontSize:38,fontWeight:FontWeight.w800,color:Colors.white)))),
        Positioned(bottom:0,right:0,child:Container(width:26,height:26,decoration:BoxDecoration(gradient:AC.goldGrad,shape:BoxShape.circle),
          child:const Icon(Icons.camera_alt_rounded,color:AC.bg,size:13))),
      ])),
      const SizedBox(height:32),
      AppField(label:'Full Name',hint:'',ctrl:_name),
      const SizedBox(height:16),
      AppField(label:'Phone Number',hint:'',ctrl:_phone,keyboard:TextInputType.phone),
      const SizedBox(height:16),
      AppField(label:'Email Address',hint:'',ctrl:_email,keyboard:TextInputType.emailAddress),
      const SizedBox(height:32),
      AppBtn(label:'Save Changes',gold:true,onTap:()=>Navigator.pop(context)),
      const SizedBox(height:32),
    ])));
}
