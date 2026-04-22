import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor:AC.bg,
    appBar:SAppBar(title:'My Vehicles',actions:[
      GestureDetector(onTap:()=>Navigator.pushNamed(context,R.addVehicle),
        child:Container(width:48,height:48,alignment:Alignment.center,
          child:Container(width:34,height:34,decoration:BoxDecoration(gradient:AC.redGrad,borderRadius:Rd.smA),
            child:const Icon(Icons.add_rounded,color:Colors.white,size:20)))),
    ]),
    body:VehicleModel.mockList.isEmpty?const EmptyState(icon:'🚗',title:'No Vehicles',sub:'Add your first vehicle'):
    ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24,vertical:14),
      itemCount:VehicleModel.mockList.length,separatorBuilder:(_,__)=>const SizedBox(height:12),
      itemBuilder:(_,i){final v=VehicleModel.mockList[i];
        return VehicleCard(make:v.make,model:v.model,year:v.year,plate:v.plate,health:v.health.toDouble())
          .animate().fadeIn(delay:(i*100).ms).slideX(begin:0.2,end:0,delay:(i*100).ms);}),
  );
}
