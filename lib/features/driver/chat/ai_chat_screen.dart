import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/services/mock_data.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});
  @override State<AiChatScreen> createState() => _AiChatScreenState();
}
class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _typing = false;
  late final List<_Msg> _msgs;
  static const _suggestions = ['What does check engine light mean?','When should I change my oil?','How to check tire pressure?'];

  @override
  void initState() {
    super.initState();
    final user = AppData.i.currentUser;
    final vehicle = AppData.i.vehicles.isEmpty ? null : AppData.i.vehicles.first;
    final vehicleName = vehicle?.fullName ?? 'your vehicle';
    _msgs = [
      _Msg(
        'Hi ${user.name.split(' ').first}! I can help with $vehicleName, maintenance, diagnostics, or uploaded OBD data.',
        false,
      ),
    ];
  }

  void _send(String txt) async {
    if(txt.trim().isEmpty) return;
    setState((){_msgs.add(_Msg(txt,true));_typing=true;});
    _ctrl.clear();
    await Future.delayed(200.ms);
    _scrollDown();
    await Future.delayed(1400.ms);
    if(!mounted) return;
    final vehicle = AppData.i.vehicles.isEmpty ? null : AppData.i.vehicles.first;
    final health = vehicle == null ? null : '${vehicle.health.toInt()}%';
    final reply = vehicle == null
        ? 'Great question. I need a saved vehicle or uploaded diagnostics to give a more specific recommendation.'
        : 'Based on ${vehicle.fullName} (${vehicle.mileage} mi, health $health), I recommend checking this with a certified technician. Would you like me to book an appointment?';
    setState((){_typing=false;_msgs.add(_Msg(reply,false));});
    await Future.delayed(100.ms);
    _scrollDown();
  }
  void _scrollDown(){ if(_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent+120, duration:300.ms, curve:Curves.easeOut); }
  @override void dispose(){_ctrl.dispose();_scroll.dispose();super.dispose();}

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:Column(children:[
      Container(padding:EdgeInsets.only(top:MediaQuery.of(context).padding.top+10,bottom:14,left:16,right:16),
        decoration:BoxDecoration(gradient:LinearGradient(colors:[const Color(0xFF0F0A20),AC.bg]),),
        child:Row(children:[
          GestureDetector(onTap:()=>Navigator.pop(context),
            child:Container(width:40,height:40,decoration:BoxDecoration(color:Colors.white.withOpacity(0.07),borderRadius:Rd.mdA),
              child:const Icon(Icons.arrow_back_ios_new_rounded,color:AC.t1,size:18))),
          const SizedBox(width:12),
          Container(width:40,height:40,decoration:BoxDecoration(
            gradient:LinearGradient(colors:[const Color(0xFF7C3AED),AC.red]),shape:BoxShape.circle),
            child:const Icon(Icons.smart_toy_rounded,color:Colors.white,size:20)),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('AI Car Assistant',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AC.t1)),
            Row(children:[Container(width:7,height:7,decoration:BoxDecoration(color:AC.success,shape:BoxShape.circle)),
              const SizedBox(width:5),const Text('Always online',style:TextStyle(fontSize:11,color:AC.success))]),
          ])),
        ])),
      if(_msgs.length<=2) Padding(padding:const EdgeInsets.fromLTRB(16,0,16,8),child:SizedBox(height:40,
        child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:_suggestions.length,
          separatorBuilder:(_,__)=>const SizedBox(width:8),
          itemBuilder:(_,i)=>GestureDetector(onTap:()=>_send(_suggestions[i]),
            child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:10),
              decoration:BoxDecoration(color:AC.red.withOpacity(0.1),borderRadius:Rd.fullA,
                border:Border.all(color:AC.red.withOpacity(0.3))),
              child:Text(_suggestions[i],style:const TextStyle(fontSize:12,color:AC.red))))))),
      Expanded(child:ListView.builder(controller:_scroll,
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
        itemCount:_msgs.length+(_typing?1:0),
        itemBuilder:(_,i){
          if(i==_msgs.length) return _TypingIndicator();
          final m=_msgs[i];
          return _Bubble(msg:m).animate().fadeIn(duration:300.ms).slideY(begin:0.15,end:0);
        })),
      Container(padding:const EdgeInsets.fromLTRB(16,10,16,32),
        decoration:const BoxDecoration(border:Border(top:BorderSide(color:AC.border,width:0.5))),
        child:Row(children:[
          Expanded(child:TextField(controller:_ctrl,
            style:const TextStyle(fontFamily:'Poppins',fontSize:14,color:AC.t1),
            decoration:InputDecoration(hintText:'Ask about your car...',
              hintStyle:const TextStyle(color:AC.t4,fontFamily:'Poppins'),
              filled:true,fillColor:AC.s2,
              border:OutlineInputBorder(borderRadius:Rd.fullA,borderSide:BorderSide.none),
              contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:12)),
            onSubmitted:_send)),
          const SizedBox(width:10),
          GestureDetector(onTap:()=>_send(_ctrl.text),
            child:Container(width:46,height:46,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle,
              boxShadow:[BoxShadow(color:AC.red.withOpacity(0.4),blurRadius:14)]),
              child:const Icon(Icons.send_rounded,color:Colors.white,size:20))),
        ])),
    ]),
  );
}

class _Msg { final String text; final bool isMe; const _Msg(this.text, this.isMe); }

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({super.key, required this.msg});
  @override Widget build(BuildContext context) => Padding(padding:const EdgeInsets.only(bottom:12),
    child:Row(mainAxisAlignment:msg.isMe?MainAxisAlignment.start:MainAxisAlignment.end,children:[
      if(!msg.isMe) Container(width:34,height:34,margin:const EdgeInsets.only(right:8),
        decoration:BoxDecoration(gradient:LinearGradient(colors:[const Color(0xFF7C3AED),AC.red]),shape:BoxShape.circle),
        child:const Icon(Icons.smart_toy_rounded,color:Colors.white,size:16)),
      Flexible(child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
        constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*0.72),
        decoration:BoxDecoration(
          gradient:msg.isMe?AC.redGrad:null, color:msg.isMe?null:AC.s2,
          borderRadius:Rd.lgA, border:msg.isMe?null:Border.all(color:AC.border,width:0.8)),
        child:Text(msg.text,style:TextStyle(fontSize:14,color:msg.isMe?Colors.white:AC.t1,height:1.5)))),
    ]));
}

class _TypingIndicator extends StatelessWidget {
  @override Widget build(BuildContext context) => Padding(padding:const EdgeInsets.only(bottom:12),
    child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[
      Container(width:34,height:34,margin:const EdgeInsets.only(right:8),
        decoration:BoxDecoration(gradient:LinearGradient(colors:[const Color(0xFF7C3AED),AC.red]),shape:BoxShape.circle),
        child:const Icon(Icons.smart_toy_rounded,color:Colors.white,size:16)),
      Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
        decoration:BoxDecoration(color:AC.s2,borderRadius:Rd.lgA,border:Border.all(color:AC.border,width:0.8)),
        child:Row(mainAxisSize:MainAxisSize.min,children:List.generate(3,(i)=>
          Container(margin:const EdgeInsets.symmetric(horizontal:2),width:6,height:6,
            decoration:BoxDecoration(color:AC.red,shape:BoxShape.circle))
            .animate(onPlay:(c)=>c.repeat(reverse:true)).fadeIn(delay:(i*150).ms).fadeOut(delay:(i*150+300).ms)))),
    ]));
}
