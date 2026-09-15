import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/theme/tokens.dart';
import '../widgets/common.dart';
import '../widgets/resivyn_image.dart';

/// Editable personal information screen.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _name = TextEditingController(text: 'Alex Johnson');
  final _email = TextEditingController(text: 'alex.johnson@email.com');
  final _phone = TextEditingController(text: '+971 50 123 4567');
  final _dob = TextEditingController(text: '15 May 1990');
  final _nationality = TextEditingController(text: 'Emirati');
  final _address = TextEditingController(text: 'Business Bay, Dubai, UAE');
  bool _editing = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _nationality.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _editing = false);
    toast(context, 'Profile updated successfully',
        icon: Icons.check_circle_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: RC.navy),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('personal_information'.tr(), style: RT.h2),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              if (_editing) {
                _save();
              } else {
                setState(() => _editing = true);
              }
            },
            child: Text(
              _editing ? 'Save' : 'Edit',
              style: RT.bodyStrong.copyWith(color: RC.teal),
            ),
          ),
          const SizedBox(width: RS.x4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ---- Avatar ----
          const SizedBox(height: RS.x8),
          Center(
            child: Column(
              children: [
                ResivynAvatar(
                  url: AppScope.read(context).avatarUrl,
                  name: _name.text,
                  size: 96,
                  ring: true,
                  onTap: () => pickProfilePhoto(
                    context,
                    onPicked: (path) =>
                        AppScope.read(context).setAvatarPath(path),
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: RC.teal,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RS.x24),

          // ---- Form ----
          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('basic_details'.tr(), style: RT.h2),
                  const SizedBox(height: RS.x20),
                  RTextField(
                    label: 'Full Name',
                    hint: 'Enter your name',
                    controller: _name,
                    icon: Icons.person_outline_rounded,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Email Address',
                    hint: 'Enter your email',
                    controller: _email,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Phone Number',
                    hint: 'Enter your phone',
                    controller: _phone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Date of Birth',
                    hint: 'DD/MM/YYYY',
                    controller: _dob,
                    icon: Icons.cake_outlined,
                    readOnly: true,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: RS.page,
            child: RCard(
              padding: const EdgeInsets.all(RS.x20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('additional_info'.tr(), style: RT.h2),
                  const SizedBox(height: RS.x20),
                  RTextField(
                    label: 'Nationality',
                    hint: 'Enter nationality',
                    controller: _nationality,
                    icon: Icons.flag_outlined,
                    readOnly: !_editing,
                  ),
                  const SizedBox(height: RS.x14),
                  RTextField(
                    label: 'Address',
                    hint: 'Enter your address',
                    controller: _address,
                    icon: Icons.location_on_outlined,
                    readOnly: !_editing,
                  ),
                ],
              ),
            ),
          ),

          if (_editing)
            Padding(
              padding: const EdgeInsets.fromLTRB(RS.x20, RS.x24, RS.x20, 0),
              child: RButton(
                'Save Changes',
                expanded: true,
                icon: Icons.check_rounded,
                onPressed: _save,
              ),
            ),

          const SizedBox(height: RS.x32),
        ],
      ),
    );
  }
}
