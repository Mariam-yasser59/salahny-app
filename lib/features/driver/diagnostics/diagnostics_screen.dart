import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_widgets.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}
class _DiagnosticsScreenState extends State<DiagnosticsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scan;
  bool _scanning = false;
  @override void initState(){ super.initState(); _scan=AnimationController(vsync:this,duration:2000.ms); }
  @override void dispose(){ _scan.dispose(); super.dispose(); }
  void _start(){ setState(()=>_scanning=true); _scan.repeat();
    Future.delayed(3500.ms,(){if(mounted){setState(()=>_scanning=false);_scan.stop();_scan.reset();
      Navigator.pushNamed(context,R.diagResult);}});}
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor:AC.bg,
    appBar:SAppBar(title:'AI Diagnostics'),
    body:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),child:Column(children:[
      const SizedBox(height:16),
      const Text('Connect & Scan',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:AC.t1)),
      const SizedBox(height:4),
      const Text('Real-time OBD-II + AI analysis',style:TextStyle(fontSize:13,color:AC.t3)),
      const SizedBox(height:36),
      PulseRing(color:_scanning?AC.red:AC.border, size:220,
        child:Container(width:130,height:130,
          decoration:BoxDecoration(
            gradient:_scanning?AC.redGrad:const LinearGradient(colors:[Color(0xFF2A2A2A),Color(0xFF1E1E1E)]),
            shape:BoxShape.circle,
            boxShadow:_scanning?[BoxShadow(color:AC.red.withOpacity(0.55),blurRadius:40)]:null),
          child:Icon(Icons.radar_rounded,color:_scanning?Colors.white:AC.t3,size:60))
          .animate(target:_scanning?1:0).rotate(end:1.0,duration:2000.ms,curve:Curves.linear)),
      const SizedBox(height:20),
      Text(_scanning?'Analyzing your vehicle…':'Ready to Scan',
        style:TextStyle(fontSize:16,fontWeight:FontWeight.w600,color:_scanning?AC.red:AC.t2))
        .animate().fadeIn(),
      const SizedBox(height:8),
      Text(_scanning?'Please wait, do not close the app':'Ensure your OBD-II adapter is connected',
        style:const TextStyle(fontSize:13,color:AC.t3)),
      const SizedBox(height:32),
      AppBtn(label:_scanning?'Scanning...':'Start Full Scan',loading:_scanning,onTap:_scanning?null:_start,
        icon:_scanning?null:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:22)),
      const SizedBox(height:28),
      AppBtn(label:'View Scan History',outline:true,onTap:()=>Navigator.pushNamed(context,R.diagHistory),
        icon:const Icon(Icons.history_rounded,color:AC.red,size:18)),
      const SizedBox(height:36),
      _ConnectionCard(),
      const SizedBox(height:32),
    ])),
  );
}
class _ConnectionCard extends StatelessWidget {
  @override Widget build(BuildContext context) => ACard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Text('OBD-II Connection Status',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:AC.t1)),
    const SizedBox(height:16),const Div(),const SizedBox(height:16),
    ...[('Bluetooth','Connected',true),('Adapter','OBD-ELM327',true),('Protocol','ISO 15765',true),('Vehicle ECU','Responding',true)]
      .map((e)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[
        Container(width:8,height:8,decoration:BoxDecoration(color:e.$3?AC.success:AC.error,shape:BoxShape.circle)),
        const SizedBox(width:10),
        Text(e.$1,style:const TextStyle(fontSize:13,color:AC.t3)),
        const Spacer(),
        Text(e.$2,style:TextStyle(fontSize:13,fontWeight:FontWeight.w600,color:e.$3?AC.success:AC.error)),
      ]))),
  ]));
}
