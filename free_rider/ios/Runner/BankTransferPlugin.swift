import Flutter
import UIKit
import CommonCrypto

/**
 * Bank Transfer Plugin for FREERIDER iOS
 * Handles bank transfers, virtual accounts, and quick transfer integrations
 */
@available(iOS 10.0, *)
public class BankTransferPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    
    // Mock data storage for testing
    private var mockAccounts: [String: BankAccount] = [:]
    private var virtualAccounts: [String: VirtualAccount] = [:]
    private var transactionHistory: [TransactionRecord] = []
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.freerider.payment/bank_transfer",
            binaryMessenger: registrar.messenger()
        )
        let instance = BankTransferPlugin()
        instance.channel = channel
        instance.initializeMockData()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createVirtualAccount":
            createVirtualAccount(call: call, result: result)
        case "processTransfer":
            processTransfer(call: call, result: result)
        case "validateAccount":
            validateAccount(call: call, result: result)
        case "getUserAccounts":
            getUserAccounts(call: call, result: result)
        case "getBalance":
            getAccountBalance(call: call, result: result)
        case "getTransferHistory":
            getTransferHistory(call: call, result: result)
        case "processTossTransfer":
            processTossTransfer(call: call, result: result)
        case "processKakaoPayTransfer":
            processKakaoPayTransfer(call: call, result: result)
        case "processNaverPayTransfer":
            processNaverPayTransfer(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func createVirtualAccount(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userId = args["userId"] as? String,
              let amount = args["amount"] as? Int,
              let cardType = args["cardType"] as? String,
              let cardNumber = args["cardNumber"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        let expireMinutes = args["expireMinutes"] as? Int ?? 30
        
        // Generate virtual account
        let accountNumber = generateVirtualAccountNumber()
        let bankCode = "KB"
        let bankName = "KB국민은행"
        let expireAt = Date().addingTimeInterval(TimeInterval(expireMinutes * 60))
        
        let virtualAccount = VirtualAccount(
            accountNumber: accountNumber,
            bankName: bankName,
            bankCode: bankCode,
            amount: amount,
            expireAt: expireAt,
            depositorName: "FREERIDER_USER",
            userId: userId,
            cardType: cardType,
            cardNumber: cardNumber
        )
        
        virtualAccounts[accountNumber] = virtualAccount
        
        // Schedule expiration
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(expireMinutes * 60)) {
            self.virtualAccounts.removeValue(forKey: accountNumber)
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let response: [String: Any] = [
            "accountNumber": accountNumber,
            "bankName": bankName,
            "bankCode": bankCode,
            "amount": amount,
            "expireAt": dateFormatter.string(from: expireAt),
            "depositorName": "FREERIDER_USER"
        ]
        
        result(response)
    }
    
    private func processTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let fromBank = args["fromBank"] as? String,
              let fromAccount = args["fromAccount"] as? String,
              let accountHolder = args["accountHolder"] as? String,
              let amount = args["amount"] as? Int,
              let pin = args["pin"] as? String,
              let cardId = args["cardId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        // Simulate async processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let accountKey = "\(fromBank):\(fromAccount)"
            
            guard let account = self.mockAccounts[accountKey] else {
                result(FlutterError(
                    code: "INVALID_ACCOUNT",
                    message: "계좌를 찾을 수 없습니다",
                    details: nil
                ))
                return
            }
            
            if account.balance < amount {
                result(FlutterError(
                    code: "INSUFFICIENT_BALANCE",
                    message: "잔액이 부족합니다",
                    details: nil
                ))
                return
            }
            
            if !self.verifyPin(pin, hashedPin: account.hashedPin) {
                result(FlutterError(
                    code: "INVALID_PIN",
                    message: "비밀번호가 일치하지 않습니다",
                    details: nil
                ))
                return
            }
            
            // Process transfer
            self.mockAccounts[accountKey]?.balance -= amount
            let transactionId = self.generateTransactionId()
            
            let transaction = TransactionRecord(
                transactionId: transactionId,
                fromBank: fromBank,
                fromAccount: fromAccount,
                amount: amount,
                timestamp: Date(),
                cardId: cardId,
                status: "SUCCESS"
            )
            
            self.transactionHistory.append(transaction)
            
            let dateFormatter = ISO8601DateFormatter()
            let response: [String: Any] = [
                "success": true,
                "transactionId": transactionId,
                "amount": amount,
                "completedAt": dateFormatter.string(from: Date()),
                "newBalance": self.mockAccounts[accountKey]?.balance ?? 0
            ]
            
            result(response)
        }
    }
    
    private func validateAccount(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bank = args["bank"] as? String,
              let account = args["account"] as? String,
              let holder = args["holder"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        // Simulate async validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let accountKey = "\(bank):\(account)"
            let isValid = self.mockAccounts[accountKey]?.holder == holder
            result(isValid)
        }
    }
    
    private func getUserAccounts(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let _ = args["userId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "userId required",
                details: nil
            ))
            return
        }
        
        // Return mock accounts for testing
        let accounts: [[String: Any]] = [
            [
                "bank": "KB",
                "bankName": "KB국민은행",
                "accountNumber": "123456789012",
                "accountHolder": "홍길동",
                "balance": 50000,
                "isDefault": true
            ],
            [
                "bank": "SHINHAN",
                "bankName": "신한은행",
                "accountNumber": "987654321098",
                "accountHolder": "홍길동",
                "balance": 100000,
                "isDefault": false
            ]
        ]
        
        result(accounts)
    }
    
    private func getAccountBalance(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bank = args["bank"] as? String,
              let account = args["account"] as? String,
              let pin = args["pin"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        let accountKey = "\(bank):\(account)"
        
        guard let mockAccount = mockAccounts[accountKey] else {
            result(FlutterError(
                code: "INVALID_ACCOUNT",
                message: "계좌를 찾을 수 없습니다",
                details: nil
            ))
            return
        }
        
        if !verifyPin(pin, hashedPin: mockAccount.hashedPin) {
            result(FlutterError(
                code: "INVALID_PIN",
                message: "비밀번호가 일치하지 않습니다",
                details: nil
            ))
            return
        }
        
        result(mockAccount.balance)
    }
    
    private func getTransferHistory(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let _ = args["userId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "userId required",
                details: nil
            ))
            return
        }
        
        let limit = args["limit"] as? Int ?? 20
        let dateFormatter = ISO8601DateFormatter()
        
        let history = Array(transactionHistory.suffix(limit)).map { transaction in
            return [
                "transactionId": transaction.transactionId,
                "amount": transaction.amount,
                "fromAccount": transaction.fromAccount,
                "toAccount": "FREERIDER_CHARGE",
                "transferredAt": dateFormatter.string(from: transaction.timestamp),
                "status": transaction.status,
                "description": "교통카드 충전"
            ] as [String: Any]
        }
        
        result(history)
    }
    
    private func processTossTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let _ = args["cardId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        // Simulate Toss API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let transactionId = "TOSS_\(self.generateTransactionId())"
            
            let response: [String: Any] = [
                "success": true,
                "transactionId": transactionId,
                "amount": amount
            ]
            
            result(response)
        }
    }
    
    private func processKakaoPayTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let _ = args["cardId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        // Simulate KakaoPay API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let transactionId = "KAKAO_\(self.generateTransactionId())"
            
            let response: [String: Any] = [
                "success": true,
                "transactionId": transactionId,
                "amount": amount
            ]
            
            result(response)
        }
    }
    
    private func processNaverPayTransfer(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let amount = args["amount"] as? Int,
              let _ = args["cardId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Required arguments missing",
                details: nil
            ))
            return
        }
        
        // Simulate NaverPay API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let transactionId = "NAVER_\(self.generateTransactionId())"
            
            let response: [String: Any] = [
                "success": true,
                "transactionId": transactionId,
                "amount": amount
            ]
            
            result(response)
        }
    }
    
    // Helper functions
    private func initializeMockData() {
        // Initialize mock bank accounts for testing
        mockAccounts["KB:123456789012"] = BankAccount(
            bank: "KB",
            account: "123456789012",
            holder: "홍길동",
            balance: 50000,
            hashedPin: hashPin("1234")
        )
        
        mockAccounts["SHINHAN:987654321098"] = BankAccount(
            bank: "SHINHAN",
            account: "987654321098",
            holder: "홍길동",
            balance: 100000,
            hashedPin: hashPin("1234")
        )
    }
    
    private func generateVirtualAccountNumber() -> String {
        let digits = "0123456789"
        var result = ""
        for _ in 0..<14 {
            let randomIndex = Int.random(in: 0..<digits.count)
            let index = digits.index(digits.startIndex, offsetBy: randomIndex)
            result.append(digits[index])
        }
        return result
    }
    
    private func generateTransactionId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let random = Int.random(in: 1000..<10000)
        return "TXN_\(timestamp)_\(random)"
    }
    
    private func hashPin(_ pin: String) -> String {
        let data = pin.data(using: .utf8)!
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPin(_ inputPin: String, hashedPin: String) -> Bool {
        return hashPin(inputPin) == hashedPin
    }
    
    // Data structures
    struct BankAccount {
        var bank: String
        var account: String
        var holder: String
        var balance: Int
        var hashedPin: String
    }
    
    struct VirtualAccount {
        var accountNumber: String
        var bankName: String
        var bankCode: String
        var amount: Int
        var expireAt: Date
        var depositorName: String
        var userId: String
        var cardType: String
        var cardNumber: String
    }
    
    struct TransactionRecord {
        var transactionId: String
        var fromBank: String
        var fromAccount: String
        var amount: Int
        var timestamp: Date
        var cardId: String
        var status: String
    }
}