import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ibct_eventos/features/users/presentation/providers/user_di.dart';
import '../../domain/repositories/auth_repository_interface.dart';
import 'auth_providers.dart';

enum ChangePasswordStatus { initial, loading, success, error }

class ChangePasswordState {
  final ChangePasswordStatus status;
  final String? errorMessage;
  
  const ChangePasswordState({this.status = ChangePasswordStatus.initial, this.errorMessage});
}

class ChangePasswordController extends Notifier<ChangePasswordState> {
  late IAuthRepository _authRepository;
  
  @override
  ChangePasswordState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const ChangePasswordState();
  }

  Future<void> changePassword(String newPassword) async {
    state = const ChangePasswordState(status: ChangePasswordStatus.loading);
    
    try {
      // 1. Change password in Firebase Auth
      await _authRepository.changePassword(newPassword);
      
      // 2. Update isFirstLogin in Firestore
      final user = _authRepository.currentUser;
      if (user != null) {
        final userRepo = ref.read(userRepositoryProvider); 
        final appUser = await userRepo.getUser(user.uid);
        
        if (appUser != null && appUser.isFirstLogin) {
           final updatedUser = appUser.copyWith(isFirstLogin: false);
           await userRepo.updateUser(updatedUser);
        }
      }

      state = const ChangePasswordState(status: ChangePasswordStatus.success);
    } catch (e) {
      state = ChangePasswordState(
        status: ChangePasswordStatus.error, 
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }
}

final changePasswordControllerProvider = NotifierProvider<ChangePasswordController, ChangePasswordState>(ChangePasswordController.new);
