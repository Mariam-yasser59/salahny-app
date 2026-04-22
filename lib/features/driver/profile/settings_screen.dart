import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif=true,_location=true,_biometric=false,_dark=true,_emailAlerts=true;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'Settings'),
    body:ListView(padding:const EdgeInsets.symmetric(horizontal:24,vertical:8),children:[
      _Group('Notifications',[
        _Toggle('Push Notifications',_notif,(v)=>setState(()=>_notif=v)),
        _Toggle('Email Alerts',_emailAlerts,(v)=>setState(()=>_emailAlerts=v)),
      ]),
      const SizedBox(height:12),
      _Group('Privacy & Security',[
        _Toggle('Location Access',_location,(v)=>setState(()=>_location=v)),
        _Toggle('Biometric Login',_biometric,(v)=>setState(()=>_biometric=v)),
      ]),
      const SizedBox(height:12),
      _Group('Appearance',[
        _Toggle('Dark Mode',_dark,(v)=>setState(()=>_dark=v)),
      ]),
    ]));
}
Widget _Group(String title, List<Widget> items) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
  Padding(padding:const EdgeInsets.only(bottom:10),
    child:Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:AC.t3,letterSpacing:0.5))),
  ACard(padding:EdgeInsets.zero,child:Column(children:items)),
]);
Widget _Toggle(String title, bool val, ValueChanged<bool> onChange) => ListTile(
  title:Text(title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:AC.t1)),
  trailing:Switch(value:val,onChanged:onChange,activeColor:AC.red),
  contentPadding:const EdgeInsets.symmetric(horizontal:16));
