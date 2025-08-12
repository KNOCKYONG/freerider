import Flutter
import PassKit

@available(iOS 10.0, *)
public class MobilePayPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.freerider.payment/mobile_pay",
            binaryMessenger: registrar.messenger()
        )
        let instance = MobilePayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "canMakePayments":
            checkCanMakePayments(result: result)
        case "hasRegisteredCards":
            checkRegisteredCards(call: call, result: result)
        case "processApplePayment":
            processApplePayment(call: call, result: result)
        case "getApplePayCards":
            getApplePayCards(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkCanMakePayments(result: @escaping FlutterResult) {
        let canMakePayments = PKPaymentAuthorizationController.canMakePayments()
        result(canMakePayments)
    }
    
    private func checkRegisteredCards(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let networks = args["networks"] as? [String] else {
            result(false)
            return
        }
        
        let paymentNetworks = networks.compactMap { network -> PKPaymentNetwork? in
            switch network {
            case "visa": return .visa
            case "masterCard": return .masterCard
            case "amex": return .amex
            default: return nil
            }
        }
        
        let hasCards = PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: paymentNetworks
        )
        result(hasCards)
    }
    
    private func processApplePayment(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(["success": false, "error": "Invalid arguments"])
            return
        }
        
        let request = createPaymentRequest(from: args)
        
        if let controller = PKPaymentAuthorizationController(paymentRequest: request) {
            controller.delegate = self
            controller.present { presented in
                if !presented {
                    result(["success": false, "error": "Could not present payment controller"])
                }
            }
            
            // Store the result callback for later use
            self.paymentResult = result
        } else {
            result(["success": false, "error": "Could not create payment controller"])
        }
    }
    
    private func createPaymentRequest(from args: [String: Any]) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        
        // Merchant configuration
        request.merchantIdentifier = args["merchantIdentifier"] as? String ?? "merchant.com.freerider.transit"
        request.countryCode = args["countryCode"] as? String ?? "KR"
        request.currencyCode = args["currencyCode"] as? String ?? "KRW"
        
        // Supported networks
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = [.capability3DS, .capabilityEMV]
        
        // Payment summary items
        if let items = args["paymentSummaryItems"] as? [[String: Any]] {
            request.paymentSummaryItems = items.compactMap { item in
                guard let label = item["label"] as? String,
                      let amountString = item["amount"] as? String,
                      let amount = Decimal(string: amountString) else {
                    return nil
                }
                return PKPaymentSummaryItem(
                    label: label,
                    amount: NSDecimalNumber(decimal: amount)
                )
            }
        }
        
        return request
    }
    
    private func getApplePayCards(result: @escaping FlutterResult) {
        // Apple Pay doesn't provide direct access to card list
        // Return mock data or integrate with Wallet API if available
        let mockCards: [[String: Any]] = [
            [
                "id": "apple_card_001",
                "type": "T-money",
                "lastFourDigits": "1234",
                "balance": 5000,
                "isDefault": true
            ]
        ]
        result(mockCards)
    }
    
    private var paymentResult: FlutterResult?
}

// MARK: - PKPaymentAuthorizationControllerDelegate
@available(iOS 10.0, *)
extension MobilePayPlugin: PKPaymentAuthorizationControllerDelegate {
    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Process the payment token
        let paymentToken = payment.token
        let paymentData = paymentToken.paymentData
        
        // Convert payment data to base64 string
        let tokenString = paymentData.base64EncodedString()
        
        // Send success result back to Flutter
        paymentResult?([
            "success": true,
            "paymentToken": tokenString,
            "transactionIdentifier": payment.token.transactionIdentifier
        ])
        
        // Complete the payment
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    public func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        controller.dismiss()
        
        // If payment wasn't processed, send cancellation
        if paymentResult != nil {
            paymentResult?([
                "success": false,
                "error": "Payment cancelled"
            ])
            paymentResult = nil
        }
    }
}