import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/user_provider.dart';
import '../../../presentation/widgets/common/custom_back_button.dart';
import '../../../presentation/widgets/common/custom_text_field.dart';
import '../../../presentation/widgets/common/custom_button.dart';

class NicknameChangeScreen extends StatefulWidget {
  const NicknameChangeScreen({super.key});

  @override
  State<NicknameChangeScreen> createState() => _NicknameChangeScreenState();
}

class _NicknameChangeScreenState extends State<NicknameChangeScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final newNickname = _nicknameController.text.trim();

    if (newNickname.isEmpty || newNickname.length < 2 || newNickname.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임은 2~20자로 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await context.read<UserProvider>().changeNickname(newNickname);

    setState(() => _isLoading = false);

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임이 변경되었습니다!")),
      );

      if (context.mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임 변경에 실패했습니다.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F8FB),
        leading: const CustomBackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.091),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: h * 0.025),
              Text(
                '새 닉네임을\n입력해주세요',
                style: TextStyle(
                  fontSize: w * 0.072,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),

              SizedBox(height: h * 0.04),

              CustomTextField(
                hintText: '닉네임 (2~20자)',
                controller: _nicknameController,
                obscureText: false,
              ),

              const Spacer(),

              CustomButton(
                text: '변경하기',
                onPressed: _isLoading ? null : _submit,
              ),

              SizedBox(height: h * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}
