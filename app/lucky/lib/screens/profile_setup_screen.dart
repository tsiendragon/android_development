import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lucky/providers/auth_provider.dart';
import 'package:lucky/providers/user_provider.dart';
import 'package:lucky/screens/home_screen.dart';
import 'package:lucky/utils/constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String userId;
  
  const ProfileSetupScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _gender = '男';
  DateTime _birthDate = DateTime(2000, 1, 1);
  String _birthTime = AppConstants.timePeriods.keys.first;
  final _birthPlaceController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;
  
  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await userProvider.saveUserInfo(
        id: widget.userId,
        name: _nameController.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
        birthTime: _birthTime,
        birthPlace: _birthPlaceController.text.trim(),
        authProvider: authProvider.authType ?? 'unknown',
      );
      
      if (success) {
        await authProvider.setProfileComplete(true);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存个人信息失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发生错误，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
    );
    
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人信息设置'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _saveProfile();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep < 2 ? '下一步' : '完成'),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('上一步'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Step 1: Basic Info
            Step(
              title: const Text('基本信息'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '姓名',
                      hintText: '请输入您的姓名',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入姓名';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('性别：'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: '男',
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const Text('男'),
                      const SizedBox(width: 16),
                      Radio<String>(
                        value: '女',
                        groupValue: _gender,
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const Text('女'),
                    ],
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),
            // Step 2: Birth Date and Time
            Step(
              title: const Text('出生日期和时间'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Birth date
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '出生日期',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        DateFormat('yyyy年MM月dd日').format(_birthDate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Birth time
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '出生时辰',
                      prefixIcon: Icon(Icons.access_time),
                    ),
                    value: _birthTime,
                    items: AppConstants.timePeriods.keys.map((String time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _birthTime = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),
            // Step 3: Birth Place
            Step(
              title: const Text('出生地点'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _birthPlaceController,
                    decoration: const InputDecoration(
                      labelText: '出生地点',
                      hintText: '请输入您的出生地点（城市）',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入出生地点';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '提示：出生地点信息将用于更准确地计算您的八字和运势。',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }
}
