import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButton extends StatelessWidget {
  final Function()? onTap;
  final String buttonText;
  final Color backgroundColor;
  final Color textColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  const MyButton({
    Key? key,
    required this.onTap,
    required this.buttonText,
    required this.backgroundColor,
    required this.textColor,
    required this.borderRadius,
    required this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: GoogleFonts.manrope(
              color: textColor, //text color
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
