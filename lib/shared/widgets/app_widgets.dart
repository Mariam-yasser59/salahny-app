import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─── APP BUTTON ──────────────────────────────────────────────────────────────
class AppBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool gold, outline, small, loading;
  final Widget? icon;
  final double? width;
  const AppBtn({super.key, required this.label, this.onTap, this.gold=false,
    this.outline=false, this.small=false, this.loading=false, this.icon, this.width});
  @override State<AppBtn> createState() => _AppBtnState();
}
class _AppBtnState extends State<AppBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() { super.initState();
    _c = AnimationController(vsync:this, duration:100.ms);
    _s = Tween(begin:1.0, end:0.94).animate(CurvedAnimation(parent:_c, curve:Curves.easeOut)); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final h = widget.small ? 46.0 : 54.0;
    final grad = widget.gold ? AC.goldGrad : AC.redGrad;
    return GestureDetector(
      onTapDown:(_)=>_c.forward(), onTapUp:(_){_c.reverse();widget.onTap?.call();}, onTapCancel:()=>_c.reverse(),
      child: AnimatedBuilder(animation:_s, builder:(_,child)=>Transform.scale(scale:_s.value,child:child),
        child: Container(width:widget.width??double.infinity, height:h,
          decoration: BoxDecoration(
            gradient: widget.outline ? null : grad,
            borderRadius: Rd.mdA,
            border: widget.outline ? Border.all(color: widget.gold ? AC.gold : AC.red, width:1.5) : null,
            boxShadow: widget.outline ? null : [BoxShadow(color:(widget.gold?AC.gold:AC.red).withOpacity(0.38), blurRadius:18, offset:const Offset(0,5))],
          ),
          child: Row(mainAxisAlignment:MainAxisAlignment.center, children:[
            if (widget.loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else ...[
              if(widget.icon!=null)...[widget.icon!,const SizedBox(width:8)],
              Text(widget.label, style:TextStyle(fontFamily:'Poppins', fontSize:widget.small?13:15,
                fontWeight:FontWeight.w700, color:widget.outline?(widget.gold?AC.gold:AC.red):Colors.white, letterSpacing:0.2)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─── APP CARD ────────────────────────────────────────────────────────────────
class ACard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding, margin;
  final VoidCallback? onTap;
  final bool glow;
  final Color? glowColor;
  const ACard({super.key, required this.child, this.padding, this.margin,
    this.onTap, this.glow=false, this.glowColor});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors:[Color(0xFF1E1E1E),Color(0xFF161616)], begin:Alignment.topLeft, end:Alignment.bottomRight),
        borderRadius: Rd.lgA,
        border: Border.all(color:const Color(0xFF2E2E2E), width:0.8),
        boxShadow: glow ? [BoxShadow(color:(glowColor??AC.red).withOpacity(0.28), blurRadius:22, spreadRadius:-3),
          BoxShadow(color:Colors.black.withOpacity(0.4), blurRadius:14, offset:const Offset(0,6))] : AS.card,
      ),
      child: ClipRRect(borderRadius: Rd.lgA,
        child: Padding(padding:padding??const EdgeInsets.all(Sp.x16), child:child)),
    ),
  );
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────
class SecHeader extends StatelessWidget {
  final String title; final String? sub, action;
  final VoidCallback? onAction;
  const SecHeader({super.key, required this.title, this.sub, this.action, this.onAction});
  @override Widget build(BuildContext context) => Row(crossAxisAlignment:CrossAxisAlignment.end, children:[
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(title, style:const TextStyle(fontSize:18, fontWeight:FontWeight.w700, color:AC.t1)),
      if(sub!=null)...[const SizedBox(height:2), Text(sub!, style:const TextStyle(fontSize:12, color:AC.t3))],
    ])),
    if(action!=null) GestureDetector(onTap:onAction,
      child:Container(padding:const EdgeInsets.symmetric(horizontal:10, vertical:4),
        decoration:BoxDecoration(color:AC.redGlow2, borderRadius:Rd.fullA, border:Border.all(color:AC.red.withOpacity(0.3))),
        child:Text(action!, style:const TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:AC.red)))),
  ]);
}

// ─── CUSTOM APPBAR ───────────────────────────────────────────────────────────
class SAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; final bool showBack;
  final List<Widget>? actions; final VoidCallback? onBack;
  const SAppBar({super.key, required this.title, this.showBack=true, this.actions, this.onBack});
  @override Size get preferredSize => const Size.fromHeight(58);
  @override Widget build(BuildContext context) => Container(
    height: 58 + MediaQuery.of(context).padding.top,
    padding: EdgeInsets.only(top:MediaQuery.of(context).padding.top, left:4, right:4),
    child: Row(children:[
      showBack ? _BarBtn(Icons.arrow_back_ios_new_rounded, onBack??()=>Navigator.pop(context)) : const SizedBox(width:48),
      Expanded(child:Text(title, textAlign:TextAlign.center,
        style:const TextStyle(fontSize:17, fontWeight:FontWeight.w700, color:AC.t1))),
      actions!=null&&actions!.isNotEmpty ? actions!.first : const SizedBox(width:48),
    ]),
  );
}
class _BarBtn extends StatelessWidget {
  final IconData icon; final VoidCallback? onTap;
  const _BarBtn(this.icon, [this.onTap]);
  @override Widget build(BuildContext context) => GestureDetector(onTap:onTap,
    child:Container(width:48, height:48, alignment:Alignment.center,
      child:Icon(icon, color:AC.t1, size:20)));
}

// ─── STATUS CHIP ─────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  const StatusChip(this.label, {super.key});
  Color get _c { switch(label) {
    case 'Active': return AC.info;
    case 'Completed': return AC.success;
    case 'Cancelled': return AC.error;
    case 'Pending': return AC.warning;
    default: return AC.t3; } }
  @override Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.symmetric(horizontal:10, vertical:4),
    decoration:BoxDecoration(color:_c.withOpacity(0.12), borderRadius:Rd.fullA, border:Border.all(color:_c.withOpacity(0.4), width:0.8)),
    child:Text(label, style:TextStyle(fontSize:11, fontWeight:FontWeight.w600, color:_c)));
}

// ─── GOLD BADGE ──────────────────────────────────────────────────────────────
class GoldBadge extends StatelessWidget {
  final String label; final IconData? icon;
  const GoldBadge(this.label, {super.key, this.icon});
  @override Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.symmetric(horizontal:8, vertical:3),
    decoration:BoxDecoration(gradient:AC.goldGrad, borderRadius:Rd.fullA,
      boxShadow:[BoxShadow(color:AC.gold.withOpacity(0.3), blurRadius:8)]),
    child:Row(mainAxisSize:MainAxisSize.min, children:[
      if(icon!=null)...[Icon(icon,size:10,color:AC.bg),const SizedBox(width:3)],
      Text(label, style:const TextStyle(fontSize:10, fontWeight:FontWeight.w700, color:AC.bg)),
    ]));
}

// ─── TEXT FIELD ──────────────────────────────────────────────────────────────
class AppField extends StatelessWidget {
  final String label, hint; final TextEditingController? ctrl;
  final bool obscure, readOnly; final TextInputType? keyboard;
  final Widget? suffix, prefix; final String? Function(String?)? validator;
  final void Function(String)? onChange; final int maxLines;
  const AppField({super.key, required this.label, required this.hint, this.ctrl,
    this.obscure=false, this.readOnly=false, this.keyboard, this.suffix,
    this.prefix, this.validator, this.onChange, this.maxLines=1});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
    Text(label, style:const TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:AC.t2)),
    const SizedBox(height:8),
    TextFormField(controller:ctrl, obscureText:obscure, readOnly:readOnly,
      keyboardType:keyboard, validator:validator, onChanged:onChange, maxLines:maxLines,
      style:const TextStyle(fontFamily:'Poppins', fontSize:14, color:AC.t1),
      decoration:InputDecoration(hintText:hint, suffixIcon:suffix, prefixIcon:prefix)),
  ]);
}

// ─── RATING STARS ────────────────────────────────────────────────────────────
class RatingStars extends StatelessWidget {
  final double rating; final double size;
  const RatingStars({super.key, required this.rating, this.size=14});
  @override Widget build(BuildContext context) => Row(mainAxisSize:MainAxisSize.min,
    children:List.generate(5,(i)=>Icon(
      i<rating.floor()?Icons.star_rounded:i<rating?Icons.star_half_rounded:Icons.star_outline_rounded,
      color:i<rating?AC.gold:AC.t4, size:size)));
}

// ─── HEALTH ARC ──────────────────────────────────────────────────────────────
class HealthArc extends StatelessWidget {
  final double value;
  const HealthArc({super.key, required this.value});
  Color get _c => value>=80?AC.success:value>=60?AC.warning:AC.error;
  @override Widget build(BuildContext context) => CustomPaint(
    painter:_ArcPaint(value:value, color:_c),
    child:SizedBox(width:120, height:72, child:Column(mainAxisAlignment:MainAxisAlignment.end, children:[
      Text('${value.toInt()}%', style:TextStyle(fontSize:26, fontWeight:FontWeight.w800, color:_c)),
      Text('Health', style:const TextStyle(fontSize:10, color:AC.t3)),
      const SizedBox(height:4),
    ])));
}
class _ArcPaint extends CustomPainter {
  final double value; final Color color;
  const _ArcPaint({required this.value, required this.color});
  @override void paint(Canvas canvas, Size size) {
    final c=Offset(size.width/2,size.height-6); const r=50.0; const sw=7.0;
    canvas.drawArc(Rect.fromCircle(center:c,radius:r), math.pi, math.pi, false,
      Paint()..color=AC.border..style=PaintingStyle.stroke..strokeWidth=sw..strokeCap=StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center:c,radius:r), math.pi, math.pi*(value/100), false,
      Paint()..shader=LinearGradient(colors:[color.withOpacity(0.5),color])
        .createShader(Rect.fromCircle(center:c,radius:r))
        ..style=PaintingStyle.stroke..strokeWidth=sw..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(_ArcPaint o) => o.value!=value;
}

// ─── SHIMMER ─────────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double w, h; final double radius;
  const ShimmerBox({super.key, required this.w, required this.h, this.radius=8});
  @override Widget build(BuildContext context) => Container(width:w, height:h,
    decoration:BoxDecoration(color:AC.s2, borderRadius:BorderRadius.circular(radius)))
    .animate(onPlay:(c)=>c.repeat()).shimmer(duration:1200.ms, color:AC.s3);
}

// ─── DIVIDER ─────────────────────────────────────────────────────────────────
class Div extends StatelessWidget {
  const Div({super.key});
  @override Widget build(BuildContext context) => const Divider(color:AC.border, thickness:0.5, height:1);
}

// ─── VEHICLE CARD ────────────────────────────────────────────────────────────
class VehicleCard extends StatelessWidget {
  final String make, model, year, plate; final double health;
  final bool selected; final VoidCallback? onTap;
  const VehicleCard({super.key, required this.make, required this.model,
    required this.year, required this.plate, required this.health, this.selected=false, this.onTap});
  Color get _hc => health>=80?AC.success:health>=60?AC.warning:AC.error;
  @override Widget build(BuildContext context) => GestureDetector(onTap:onTap,
    child:AnimatedContainer(duration:250.ms,
      padding:const EdgeInsets.all(16),
      decoration:BoxDecoration(
        gradient:const LinearGradient(colors:[Color(0xFF1E1E1E),Color(0xFF161616)]),
        borderRadius:Rd.lgA,
        border:Border.all(color:selected?AC.red:AC.border, width:selected?1.5:0.8),
        boxShadow:selected?[BoxShadow(color:AC.red.withOpacity(0.22),blurRadius:18)]:null,
      ),
      child:Row(children:[
        AnimatedContainer(duration:250.ms, width:50, height:50,
          decoration:BoxDecoration(color:selected?AC.red.withOpacity(0.15):AC.s3, borderRadius:Rd.mdA),
          child:Icon(Icons.directions_car_rounded, color:selected?AC.red:AC.t2, size:26)),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text('$make $model', style:const TextStyle(fontSize:15, fontWeight:FontWeight.w700, color:AC.t1)),
          Text('$year • $plate', style:const TextStyle(fontSize:12, color:AC.t3)),
        ])),
        Column(children:[
          Text('${health.toInt()}%', style:TextStyle(fontSize:16, fontWeight:FontWeight.w800, color:_hc)),
          Text('health', style:const TextStyle(fontSize:10, color:AC.t3)),
        ]),
      ]),
    ));
}

// ─── STAT TILE ───────────────────────────────────────────────────────────────
class StatTile extends StatelessWidget {
  final String label, value; final IconData icon; final Color color; final String? unit;
  const StatTile({super.key, required this.label, required this.value, required this.icon, required this.color, this.unit});
  @override Widget build(BuildContext context) => ACard(padding:const EdgeInsets.all(14),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Container(width:36, height:36, decoration:BoxDecoration(color:color.withOpacity(0.14), borderRadius:Rd.smA),
        child:Icon(icon, color:color, size:18)),
      const SizedBox(height:10),
      Row(crossAxisAlignment:CrossAxisAlignment.end, children:[
        Text(value, style:const TextStyle(fontSize:22, fontWeight:FontWeight.w800, color:AC.t1)),
        if(unit!=null)...[const SizedBox(width:3),
          Padding(padding:const EdgeInsets.only(bottom:2),
            child:Text(unit!, style:const TextStyle(fontSize:11, color:AC.t3)))],
      ]),
      const SizedBox(height:3),
      Text(label, style:const TextStyle(fontSize:11, color:AC.t3)),
    ]));
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String icon, title, sub;
  const EmptyState({super.key, required this.icon, required this.title, required this.sub});
  @override Widget build(BuildContext context) => Center(child:Column(mainAxisSize:MainAxisSize.min, children:[
    Text(icon, style:const TextStyle(fontSize:56)),
    const SizedBox(height:16),
    Text(title, style:const TextStyle(fontSize:18, fontWeight:FontWeight.w700, color:AC.t1)),
    const SizedBox(height:8),
    Text(sub, textAlign:TextAlign.center, style:const TextStyle(fontSize:13, color:AC.t3, height:1.5)),
  ]));
}

// ─── PULSE RING ──────────────────────────────────────────────────────────────
class PulseRing extends StatelessWidget {
  final Color color; final double size; final Widget child;
  const PulseRing({super.key, required this.color, required this.size, required this.child});
  @override Widget build(BuildContext context) => SizedBox(width:size, height:size,
    child:Stack(alignment:Alignment.center, children:[
      Container(width:size, height:size, decoration:BoxDecoration(shape:BoxShape.circle,
        border:Border.all(color:color.withOpacity(0.15), width:1.5)))
        .animate(onPlay:(c)=>c.repeat()).scale(begin:const Offset(0.8,0.8), end:const Offset(1.0,1.0), duration:1500.ms)
        .fadeOut(begin:0.5, duration:1500.ms),
      Container(width:size*0.7, height:size*0.7, decoration:BoxDecoration(shape:BoxShape.circle,
        border:Border.all(color:color.withOpacity(0.25), width:1.5)))
        .animate(onPlay:(c)=>c.repeat()).scale(begin:const Offset(0.8,0.8), end:const Offset(1.0,1.0), duration:1500.ms, delay:300.ms)
        .fadeOut(begin:0.5, duration:1500.ms, delay:300.ms),
      child,
    ]));
}

// ─── INFO ROW ────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label, value; final bool bold;
  const InfoRow({super.key, required this.label, required this.value, this.bold=false});
  @override Widget build(BuildContext context) => Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
    Text(label, style:const TextStyle(fontSize:13, color:AC.t3)),
    Text(value, style:TextStyle(fontSize:bold?15:14, fontWeight:bold?FontWeight.w700:FontWeight.w600, color:bold?AC.gold:AC.t1)),
  ]);
}
