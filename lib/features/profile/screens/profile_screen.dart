// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../auth/services/auth_service.dart';
// import '../../maps/screens/map_screen.dart';



// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final auth = context.read<AuthService>();

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: auth.logout,
//           )
//         ],
//       ),
//       body: Center(
//   child: Column(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       Text(
//         'Logged in as: ${auth.user?.phoneNumber}',
//         style: const TextStyle(fontSize: 18),
//       ),
//       const SizedBox(height: 24),
//      ElevatedButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const MapScreen()),
//           );
//         },
//         child: const Text("Select Land Location"),
//       ),
//     ],
//   ),
// ),

      
//     );
//   }
// }
