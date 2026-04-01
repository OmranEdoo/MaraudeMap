import 'package:flutter/material.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 16),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: Image(
            image: AssetImage('assets/images/logo_claire_sans_texte.png'),
          ),
        ),
      ),
    );
  }
}
