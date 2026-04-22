import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override Widget build(BuildContext context){
    const u=UserModel.mock;
    return Scaffold(backgroundColor:AC.bg,
      appBar:SAppBar(title:'My Profile',actions:[
        GestureDetector(onTap:()=>Navigator.pushNamed(context,R.editProfile),
          child:Container(width:48,height:48,alignment:Alignment.center,
            child:const Icon(Icons.edit_outlined,color:AC.t1,size:20))),
      ]),
      body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
        ACard(glow:true,glowColor:AC.red,child:Column(children:[
          Row(children:[
            Container(width:70,height:70,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle),
              child:Center(child:Text(u.name[0],style:const TextStyle(fontSize:32,fontWeight:FontWeight.w800,color:Colors.white)))),
            const SizedBox(width:16),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(u.name,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:AC.t1)),
              Text(u.phone,style:const TextStyle(fontSize:13,color:AC.t3)),
              const SizedBox(height:6),
              const GoldBadge('Premium Member',icon:Icons.workspace_premium_rounded),
            ])),
          ]),
          const SizedBox(height:16),const Div(),const SizedBox(height:16),
          Row(children:[
            _SP('${u.totalBookings}','Bookings',AC.info),const SizedBox(width:10),
            _SP('${u.rating}','Rating',AC.gold),const SizedBox(width:10),
            _SP('\$${u.walletBalance.toInt()}','Wallet',AC.success),
          ]),
        ])).animate().fadeIn(duration:400.ms),
        const SizedBox(height:24),
        _MenuSec('Account',[
          _MI(Icons.directions_car_rounded,'My Vehicles',R.vehicles),
          _MI(Icons.history_rounded,'Booking History',R.bookingTrack),
          _MI(Icons.workspace_premium_rounded,'Subscription',R.packages),
          _MI(Icons.notifications_outlined,'Notifications',R.notifications),
        ]).animate().fadeIn(delay:200.ms),
        const SizedBox(height:14),
        _MenuSec('Preferences',[
          _MI(Icons.settings_outlined,'Settings',R.settings),
          _MI(Icons.privacy_tip_outlined,'Privacy Policy',R.privacy),
          _MI(Icons.info_outline_rounded,'About Salahny',R.about),
        ]).animate().fadeIn(delay:300.ms),
        const SizedBox(height:14),
        ACard(padding:EdgeInsets.zero,child:ListTile(
          onTap:()async{await MockData.logout();if(context.mounted)Navigator.pushNamedAndRemoveUntil(context,R.roleSelect,(_)=>false);},
          leading:Container(width:38,height:38,decoration:BoxDecoration(color:AC.error.withOpacity(0.12),borderRadius:Rd.smA),
            child:const Icon(Icons.logout_rounded,color:AC.error,size:20)),
          title:const Text('Sign Out',style:TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:AC.error)),
          contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:4),
        )).animate().fadeIn(delay:400.ms),
        const SizedBox(height:100),
      ])));
  }
}
class _SP extends StatelessWidget {
  final String v,l; final Color c;
  const _SP(this.v,this.l,this.c);
  @override Widget build(BuildContext context)=>Expanded(child:Container(
    padding:const EdgeInsets.symmetric(vertical:10),
    decoration:BoxDecoration(color:c.withOpacity(0.08),borderRadius:Rd.mdA,border:Border.all(color:c.withOpacity(0.2))),
    child:Column(children:[Text(v,style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:c)),
      Text(l,style:const TextStyle(fontSize:10,color:AC.t3))])));
}
class _MenuSec extends StatelessWidget {
  final String title; final List<_MI> items;
  const _MenuSec(this.title,this.items);
  @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Padding(padding:const EdgeInsets.only(bottom:10),
      child:Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:AC.t3,letterSpacing:0.5))),
    ACard(padding:EdgeInsets.zero,child:Column(children:items.asMap().entries.map((e)=>Column(children:[
      ListTile(onTap:()=>Navigator.pushNamed(context,e.value.route),
        leading:Container(width:36,height:36,decoration:BoxDecoration(color:AC.s3,borderRadius:Rd.smA),
          child:Icon(e.value.icon,color:AC.t2,size:18)),
        title:Text(e.value.title,style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:AC.t1)),
        trailing:const Icon(Icons.arrow_forward_ios_rounded,size:13,color:AC.t3),
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:3)),
      if(e.key<items.length-1) const Padding(padding:EdgeInsets.symmetric(horizontal:16),child:Div()),
    ])).toList())),
  ]);
}
class _MI{final IconData icon;final String title,route;const _MI(this.icon,this.title,this.route);}
