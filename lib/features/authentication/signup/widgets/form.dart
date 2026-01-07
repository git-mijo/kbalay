import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../../widgets/custom_icon_widget.dart';

/// Signup form widget with complete personal information fields.
class SignUpFormWidget extends StatefulWidget {
  const SignUpFormWidget({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.contactController,
    required this.addressController,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
    required this.onForgotPassword,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController contactController;
  final TextEditingController addressController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  final GlobalKey<FormState> formKey;
  final VoidCallback onForgotPassword;

  @override
  State<SignUpFormWidget> createState() => _SignUpFormWidgetState();
}

class _SignUpFormWidgetState extends State<SignUpFormWidget> {
  bool _isPasswordVisible = false;

  // Error tracking
  String? _firstNameError;
  String? _lastNameError;
  String? _contactError;
  String? _addressError;
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// FIRST NAME
          _buildTextField(
            controller: widget.firstNameController,
            label: "First Name",
            hint: "Enter first name",
            icon: "user",
            errorText: _firstNameError,
            validator: (value) {
              final error = _validateRequired(value, "First Name");
              setState(() => _firstNameError = error);
              return error;
            },
          ),
          SizedBox(height: 2.h),

          /// LAST NAME
          _buildTextField(
            controller: widget.lastNameController,
            label: "Last Name",
            hint: "Enter last name",
            icon: "user",
            errorText: _lastNameError,
            validator: (value) {
              final error = _validateRequired(value, "Last Name");
              setState(() => _lastNameError = error);
              return error;
            },
          ),
          SizedBox(height: 2.h),

          /// CONTACT NUMBER
          _buildTextField(
            controller: widget.contactController,
            label: "Contact Number",
            hint: "09XXXXXXXXX",
            icon: "phone",
            keyboardType: TextInputType.phone,
            errorText: _contactError,
            validator: (value) {
              final error = _validatePhone(value);
              setState(() => _contactError = error);
              return error;
            },
          ),
          SizedBox(height: 2.h),

          /// FULL ADDRESS
          _buildTextField(
            controller: widget.addressController,
            label: "Full Address",
            hint: "Enter your full address",
            icon: "location",
            maxLines: 2,
            errorText: _addressError,
            validator: (value) {
              final error = _validateRequired(value, "Address");
              setState(() => _addressError = error);
              return error;
            },
          ),
          SizedBox(height: 2.h),

          /// EMAIL
          _buildTextField(
            controller: widget.emailController,
            label: "Email Address",
            hint: "Enter your email",
            icon: "email",
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            validator: (value) {
              final error = _validateEmail(value);
              setState(() => _emailError = error);
              return error;
            },
          ),
          SizedBox(height: 2.h),

          /// PASSWORD
          TextFormField(
            controller: widget.passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'lock',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
              ),
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: _isPasswordVisible
                      ? 'visibility'
                      : 'visibility_off',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
                onPressed: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible),
              ),
              errorText: _passwordError,
            ),
            onChanged: (value) {
              if (_passwordError != null) {
                setState(() => _passwordError = _validatePassword(value));
              }
            },
            validator: (value) {
              final error = _validatePassword(value);
              setState(() => _passwordError = error);
              return error;
            },
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  // Reusable TextFormField builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String icon,
    required String? errorText,
    required FormFieldValidator<String> validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
        ),
      ),
      validator: validator,
      onChanged: (value) {
        if (errorText != null) {
          setState(() => validator(value));
        }
      },
    );
  }

  // Validation helpers
  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return "$field is required";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Contact number is required";
    final regex = RegExp(r'^(09|\+639)\d{9}$');
    if (!regex.hasMatch(value)) return "Invalid PH mobile number";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return "Please enter a valid email";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Password must be at least 6 characters";
    return null;
  }
}
