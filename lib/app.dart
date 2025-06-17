import 'package:blog_app/views/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/auth_controller.dart';
import 'controllers/post_controller.dart';
import 'controllers/user_controller.dart';
import 'controllers/notification_controller.dart';
import 'models/post_model.dart';

import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/home/feed_screen.dart';
import 'views/home/post_detail_screen.dart';
import 'views/post/create_post_screen.dart';
import 'views/post/edit_post_screen.dart';
import 'views/post/post_screen.dart';
import 'views/profile/profile_screen.dart';
import 'views/profile/edit_profile_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const FeedScreen(),
      routes: [
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: 'create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: 'profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            return ProfileScreen(viewUserId: userId);
          },
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: 'edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: 'my-posts',
          builder: (context, state) => const PostScreen(),
        ),
        GoRoute(
          path: 'post-detail',
          builder:
              (context, state) => PostDetailScreen(post: state.extra as Post),
        ),
        GoRoute(
          path: 'edit-post',
          builder:
              (context, state) => EditPostScreen(post: state.extra as Post),
        ),
      ],
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const color = const Color.fromARGB(255, 229, 33, 243);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PostController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
      ],
      child: MaterialApp.router(
        title: 'Blog It',
        routerConfig: _router,
        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color.fromARGB(255, 183, 170, 144),
          visualDensity: VisualDensity.adaptivePlatformDensity,

          appBarTheme: AppBarTheme(
            backgroundColor: const Color.fromARGB(255, 10, 9, 6),
            iconTheme: const IconThemeData(
              color: Color.fromARGB(255, 88, 65, 130),
            ),
            titleTextStyle: GoogleFonts.pacifico(
              fontSize: 26,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),

          textTheme: GoogleFonts.poppinsTextTheme().copyWith(
            titleLarge: GoogleFonts.roboto(
              fontSize: 18,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
