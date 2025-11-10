class WalletStateService {
  static final WalletStateService _instance = WalletStateService._internal();
  factory WalletStateService() => _instance;
  WalletStateService._internal();

  bool _isViewingWallet = false;

  void setViewingWallet(bool viewing) {
    _isViewingWallet = viewing;
  }

  bool isViewingWallet() {
    return _isViewingWallet;
  }

}