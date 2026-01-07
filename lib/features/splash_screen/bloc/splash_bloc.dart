import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hoa/core/app_export.dart';
import 'package:flutter_hoa/features/splash_screen/bloc/splash_state.dart';

// class SplashBloc extends Cubit<SplashState>{
//   SplashBloc()
//     :super(
//       SplashState.init(),
//     );

//   void init({ required BuildContext context}){
//     Future.delayed(
//       const Duration(seconds: 3),
//     (){
//       nextScreenPushNamedandRemoveUntil(
//         context,
//         AppRoutes.onboardingFlow,
//       )

//     },);
//   }
// }
