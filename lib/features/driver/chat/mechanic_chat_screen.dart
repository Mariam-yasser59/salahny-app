import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class MechanicChatScreen extends StatelessWidget {
  const MechanicChatScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    body:Column(children:[
      Container(padding:EdgeInsets.only(top:MediaQuery.of(context).padding.top+10,bottom:14,left:16,right:16),
        decoration:const BoxDecoration(border:Border(bottom:BorderSide(color:AC.border,width:0.5))),
        child:Row(children:[
          GestureDetector(onTap:()=>Navigator.pop(context),
            child:Container(width:40,height:40,decoration:BoxDecoration(color:AC.s2,borderRadius:Rd.mdA),
              child:const Icon(Icons.arrow_back_ios_new_rounded,color:AC.t1,size:18))),
          const SizedBox(width:12),
          Container(width:42,height:42,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle),
            child:const Center(child:Text('P',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:Colors.white)))),
          const SizedBox(width:10),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('ProTech Auto',style:TextStyle(fontSize:15,fontWeight:FontWeight.w700,color:AC.t1)),
            Row(children:[Container(width:7,height:7,decoration:BoxDecoration(color:AC.success,shape:BoxShape.circle)),
              const SizedBox(width:5),const Text('Online',style:TextStyle(fontSize:11,color:AC.success))]),
          ])),
          const Icon(Icons.call_rounded,color:AC.red,size:24),
        ])),
      Expanded(child:ListView(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),children:[
        _B('Hello! Your vehicle is in the garage. I\'ll start the inspection shortly.',false),
        _B('Hi, thanks! Please let me know if you find any issues.',true),
        _B('Inspection is done. Found minor brake wear. Recommend replacement within 2,000 miles.',false),
        _B('How much would that cost?',true),
      ])),
      Container(padding:const EdgeInsets.fromLTRB(16,10,16,32),
        decoration:const BoxDecoration(border:Border(top:BorderSide(color:AC.border,width:0.5))),
        child:Row(children:[
          Expanded(child:TextField(style:const TextStyle(fontFamily:'Poppins',fontSize:14,color:AC.t1),
            decoration:InputDecoration(hintText:'Type a message...',hintStyle:const TextStyle(color:AC.t4,fontFamily:'Poppins'),
              filled:true,fillColor:AC.s2,border:OutlineInputBorder(borderRadius:Rd.fullA,borderSide:BorderSide.none),
              contentPadding:const EdgeInsets.symmetric(horizontal:18,vertical:12)))),
          const SizedBox(width:10),
          Container(width:46,height:46,decoration:BoxDecoration(gradient:AC.redGrad,shape:BoxShape.circle),
            child:const Icon(Icons.send_rounded,color:Colors.white,size:20)),
        ])),
    ]),
  );
}
class _B extends StatelessWidget {
  final String text; final bool isMe;
  const _B(this.text, this.isMe);
  @override Widget build(BuildContext context) => Padding(padding:const EdgeInsets.only(bottom:12),
    child:Row(mainAxisAlignment:isMe?MainAxisAlignment.start:MainAxisAlignment.end,children:[
      Flexible(child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),
        constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*0.72),
        decoration:BoxDecoration(gradient:isMe?AC.redGrad:null,color:isMe?null:AC.s2,
          borderRadius:Rd.lgA,border:isMe?null:Border.all(color:AC.border,width:0.8)),
        child:Text(text,style:TextStyle(fontSize:14,color:isMe?Colors.white:AC.t1,height:1.5)))),
    ]));
}
