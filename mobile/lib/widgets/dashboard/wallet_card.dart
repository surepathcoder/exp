import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../utils/color_parser.dart';

class WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback? onTap;

  const WalletCard({
    super.key,
    required this.wallet,
    this.onTap,
  });

  IconData _getWalletIcon(String iconName, String type) {
    switch (iconName.toLowerCase()) {
      case 'account_balance':
      case 'bank':
        return Icons.account_balance;
      case 'payments':
      case 'mobile_money':
      case 'phone':
        return Icons.phone_android;
      case 'credit_card':
      case 'card':
        return Icons.credit_card;
      case 'wallet_travel':
      case 'cash':
        return Icons.wallet_travel;
      default:
        // fallback to type
        if (type == 'bank') return Icons.account_balance;
        if (type == 'mobile_money') return Icons.phone_android;
        if (type == 'credit_card') return Icons.credit_card;
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = ColorParser.fromHex(wallet.color);
    final format = NumberFormat.currency(
      symbol: wallet.currency == 'USD' ? '\$' : '${wallet.currency} ',
      decimalDigits: wallet.currency == 'USD' ? 2 : 0,
    );

    return Container(
      width: 170,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            themeColor.withOpacity(0.85),
            themeColor.withOpacity(0.60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getWalletIcon(wallet.icon, wallet.type),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    Text(
                      wallet.currency,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  wallet.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  format.format(wallet.balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
