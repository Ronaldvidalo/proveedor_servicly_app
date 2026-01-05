class PaymentConfig {
  // Credenciales de PayPal Sandbox
  
  static const String clientId = 'Ac76q4pCAirOUQ4MQjrk_-WPcWs5Kk__yvXvZRohOzOMaKL-DBb7zQkbrafVh_-X1fSvA-WzPEwkgDxR'; 
  static const String secretKey = 'EKC7IhIgVO6nEmHxhsCosfGkmolicuNlJTxXETCXkZlVfIdBmkfv8zcOCoU0zGLZAx_7oLWZ-iSyWuAO';

  // Cambia a false cuando vayas a Producción (Live)
  static const bool isSandbox = true;

  static const String returnUrl = "https://samplesite.com/return";
  static const String cancelUrl = "https://samplesite.com/cancel";
}