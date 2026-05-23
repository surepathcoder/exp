import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../services/wallets_api_service.dart';

class WalletState {
  final List<Wallet> wallets;
  final bool isLoading;
  final String? error;

  WalletState({
    required this.wallets,
    required this.isLoading,
    this.error,
  });

  factory WalletState.initial() {
    return WalletState(
      wallets: [],
      isLoading: false,
    );
  }

  WalletState copyWith({
    List<Wallet>? wallets,
    bool? isLoading,
    String? error,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletsApiService _apiService;

  WalletNotifier(this._apiService) : super(WalletState.initial()) {
    fetchWallets();
  }

  Future<void> fetchWallets() async {
    state = state.copyWith(isLoading: true);
    try {
      final wallets = await _apiService.getWallets();
      state = state.copyWith(wallets: wallets, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createWallet({
    required String name,
    required String type,
    required String currency,
    required double openingBalance,
    required String icon,
    required String color,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final wallet = await _apiService.createWallet(
        name: name,
        type: type,
        currency: currency,
        openingBalance: openingBalance,
        icon: icon,
        color: color,
      );
      state = state.copyWith(
        wallets: [...state.wallets, wallet],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> archiveWallet(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteWallet(id);
      // Re-fetch to let backend handle delete vs archive state
      await fetchWallets();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  final apiService = ref.watch(walletsApiServiceProvider);
  return WalletNotifier(apiService);
});
