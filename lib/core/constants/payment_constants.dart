/// Contiene listas predefinidas para la app, como bancos, wallets y criptomonedas por país.
class PaymentConstants {
  /// Map de listas de bancos, la clave es el nombre del país (ej: "Argentina").
  static const Map<String, List<String>> kBankLists = {
    'Argentina': [
      'Banco Galicia',
      'Banco Santander',
      'Banco BBVA',
      'Banco Macro',
      'Banco Nación',
      'Banco Provincia',
      'Banco Ciudad',
      'ICBC',
      'HSBC',
      'Banco Patagonia',
      'Brubank',
      'Reba',
      'Otro', // Siempre incluir "Otro"
    ],
    'Venezuela': [
      'Banco de Venezuela',
      'Banesco',
      'Banco Provincial',
      'Mercantil',
      'BOD (Banco Occidental de Descuento)',
      'Bancaribe',
      'Banco Nacional de Crédito (BNC)',
      'Banplus',
      'Otro', // Siempre incluir "Otro"
    ],
    'Genérico': [
      'Mi Banco',
      'Otro',
    ],
  };

  /// Map de listas de wallets/proveedores de pago digital por país.
  static const Map<String, List<String>> kWalletLists = {
    'Argentina': [
      'Mercado Pago',
      'Ualá',
      'Lemon Cash',
      'Naranja X',
      'Personal Pay',
      'Cuenta DNI',
      'Otro', // Siempre incluir "Otro"
    ],
    'Venezuela': [
      'Pago Móvil',
      'Zelle',
      'Binance Pay',
      'Paypal',
      'Otro', // Siempre incluir "Otro"
    ],
    'Genérico': [
      'PayPal',
      'Stripe',
      'Transferencia Digital',
      'Otro',
    ],
  };

  /// Lista de criptomonedas comunes (generalmente no depende del país).
  static const List<String> kCryptoLists = [
    'Bitcoin (BTC)',
    'Ethereum (ETH)',
    'Tether (USDT)',
    'Binance Coin (BNB)',
    'USD Coin (USDC)',
    'Ripple (XRP)',
    'Solana (SOL)',
    'Cardano (ADA)',
    'Dogecoin (DOGE)',
    'Polkadot (DOT)',
    'Litecoin (LTC)',
    'Tron (TRX)',
    'Arbitrum (ARB)',
    'Otro'
  ];
}