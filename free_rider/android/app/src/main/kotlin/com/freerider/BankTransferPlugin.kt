package com.freerider

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*
import java.text.SimpleDateFormat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.security.MessageDigest

/**
 * Bank Transfer Plugin for FREERIDER
 * Handles bank transfers, virtual accounts, and quick transfer integrations
 */
class BankTransferPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Mock implementations for testing
    // In production, these would integrate with real banking APIs
    private val mockAccounts = mutableMapOf<String, BankAccount>()
    private val virtualAccounts = mutableMapOf<String, VirtualAccount>()
    private val transactionHistory = mutableListOf<TransactionRecord>()

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.freerider.payment/bank_transfer")
        channel.setMethodCallHandler(this)
        initializeMockData()
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        mainScope.cancel()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "createVirtualAccount" -> createVirtualAccount(call, result)
            "processTransfer" -> processTransfer(call, result)
            "validateAccount" -> validateAccount(call, result)
            "getUserAccounts" -> getUserAccounts(call, result)
            "getBalance" -> getAccountBalance(call, result)
            "getTransferHistory" -> getTransferHistory(call, result)
            "processTossTransfer" -> processTossTransfer(call, result)
            "processKakaoPayTransfer" -> processKakaoPayTransfer(call, result)
            "processNaverPayTransfer" -> processNaverPayTransfer(call, result)
            else -> result.notImplemented()
        }
    }

    private fun createVirtualAccount(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val userId = call.argument<String>("userId") ?: throw IllegalArgumentException("userId required")
                val amount = call.argument<Int>("amount") ?: throw IllegalArgumentException("amount required")
                val cardType = call.argument<String>("cardType") ?: throw IllegalArgumentException("cardType required")
                val cardNumber = call.argument<String>("cardNumber") ?: throw IllegalArgumentException("cardNumber required")
                val expireMinutes = call.argument<Int>("expireMinutes") ?: 30

                // Generate virtual account
                val accountNumber = generateVirtualAccountNumber()
                val bankCode = "KB" // Using KB as default for virtual accounts
                val bankName = "KB국민은행"
                val expireAt = Calendar.getInstance().apply {
                    add(Calendar.MINUTE, expireMinutes)
                }.time
                
                val virtualAccount = VirtualAccount(
                    accountNumber = accountNumber,
                    bankName = bankName,
                    bankCode = bankCode,
                    amount = amount,
                    expireAt = expireAt,
                    depositorName = "FREERIDER_USER",
                    userId = userId,
                    cardType = cardType,
                    cardNumber = cardNumber
                )
                
                virtualAccounts[accountNumber] = virtualAccount
                
                // Schedule expiration
                Handler(Looper.getMainLooper()).postDelayed({
                    virtualAccounts.remove(accountNumber)
                }, expireMinutes * 60 * 1000L)
                
                val response = mapOf(
                    "accountNumber" to accountNumber,
                    "bankName" to bankName,
                    "bankCode" to bankCode,
                    "amount" to amount,
                    "expireAt" to SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(expireAt),
                    "depositorName" to "FREERIDER_USER"
                )
                
                result.success(response)
            } catch (e: Exception) {
                result.error("CREATE_VIRTUAL_ACCOUNT_ERROR", e.message, null)
            }
        }
    }

    private fun processTransfer(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val fromBank = call.argument<String>("fromBank") ?: throw IllegalArgumentException("fromBank required")
                val fromAccount = call.argument<String>("fromAccount") ?: throw IllegalArgumentException("fromAccount required")
                val accountHolder = call.argument<String>("accountHolder") ?: throw IllegalArgumentException("accountHolder required")
                val amount = call.argument<Int>("amount") ?: throw IllegalArgumentException("amount required")
                val pin = call.argument<String>("pin") ?: throw IllegalArgumentException("pin required")
                val cardId = call.argument<String>("cardId") ?: throw IllegalArgumentException("cardId required")
                
                // Simulate validation
                delay(500) // Simulate network delay
                
                // Check mock account balance
                val accountKey = "$fromBank:$fromAccount"
                val account = mockAccounts[accountKey]
                
                if (account == null) {
                    result.error("INVALID_ACCOUNT", "계좌를 찾을 수 없습니다", null)
                    return@launch
                }
                
                if (account.balance < amount) {
                    result.error("INSUFFICIENT_BALANCE", "잔액이 부족합니다", null)
                    return@launch
                }
                
                // Verify PIN (mock verification)
                if (!verifyPin(pin, account.hashedPin)) {
                    result.error("INVALID_PIN", "비밀번호가 일치하지 않습니다", null)
                    return@launch
                }
                
                // Process transfer
                account.balance -= amount
                val transactionId = generateTransactionId()
                
                val transaction = TransactionRecord(
                    transactionId = transactionId,
                    fromBank = fromBank,
                    fromAccount = fromAccount,
                    amount = amount,
                    timestamp = Date(),
                    cardId = cardId,
                    status = "SUCCESS"
                )
                
                transactionHistory.add(transaction)
                
                val response = mapOf(
                    "success" to true,
                    "transactionId" to transactionId,
                    "amount" to amount,
                    "completedAt" to SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(Date()),
                    "newBalance" to account.balance
                )
                
                result.success(response)
            } catch (e: Exception) {
                result.error("TRANSFER_ERROR", e.message, null)
            }
        }
    }

    private fun validateAccount(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val bank = call.argument<String>("bank") ?: throw IllegalArgumentException("bank required")
                val account = call.argument<String>("account") ?: throw IllegalArgumentException("account required")
                val holder = call.argument<String>("holder") ?: throw IllegalArgumentException("holder required")
                
                delay(300) // Simulate API call
                
                // Mock validation - check if account exists
                val accountKey = "$bank:$account"
                val isValid = mockAccounts.containsKey(accountKey) && 
                              mockAccounts[accountKey]?.holder == holder
                
                result.success(isValid)
            } catch (e: Exception) {
                result.error("VALIDATION_ERROR", e.message, null)
            }
        }
    }

    private fun getUserAccounts(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val userId = call.argument<String>("userId") ?: throw IllegalArgumentException("userId required")
                
                // Return mock accounts for testing
                val accounts = listOf(
                    mapOf(
                        "bank" to "KB",
                        "bankName" to "KB국민은행",
                        "accountNumber" to "123456789012",
                        "accountHolder" to "홍길동",
                        "balance" to 50000,
                        "isDefault" to true
                    ),
                    mapOf(
                        "bank" to "SHINHAN",
                        "bankName" to "신한은행",
                        "accountNumber" to "987654321098",
                        "accountHolder" to "홍길동",
                        "balance" to 100000,
                        "isDefault" to false
                    )
                )
                
                result.success(accounts)
            } catch (e: Exception) {
                result.error("GET_ACCOUNTS_ERROR", e.message, null)
            }
        }
    }

    private fun getAccountBalance(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val bank = call.argument<String>("bank") ?: throw IllegalArgumentException("bank required")
                val account = call.argument<String>("account") ?: throw IllegalArgumentException("account required")
                val pin = call.argument<String>("pin") ?: throw IllegalArgumentException("pin required")
                
                delay(300) // Simulate API call
                
                val accountKey = "$bank:$account"
                val mockAccount = mockAccounts[accountKey]
                
                if (mockAccount == null) {
                    result.error("INVALID_ACCOUNT", "계좌를 찾을 수 없습니다", null)
                    return@launch
                }
                
                if (!verifyPin(pin, mockAccount.hashedPin)) {
                    result.error("INVALID_PIN", "비밀번호가 일치하지 않습니다", null)
                    return@launch
                }
                
                result.success(mockAccount.balance)
            } catch (e: Exception) {
                result.error("BALANCE_ERROR", e.message, null)
            }
        }
    }

    private fun getTransferHistory(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val userId = call.argument<String>("userId") ?: throw IllegalArgumentException("userId required")
                val limit = call.argument<Int>("limit") ?: 20
                
                val history = transactionHistory
                    .takeLast(limit)
                    .map { transaction ->
                        mapOf(
                            "transactionId" to transaction.transactionId,
                            "amount" to transaction.amount,
                            "fromAccount" to transaction.fromAccount,
                            "toAccount" to "FREERIDER_CHARGE",
                            "transferredAt" to SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).format(transaction.timestamp),
                            "status" to transaction.status,
                            "description" to "교통카드 충전"
                        )
                    }
                
                result.success(history)
            } catch (e: Exception) {
                result.error("HISTORY_ERROR", e.message, null)
            }
        }
    }

    private fun processTossTransfer(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val amount = call.argument<Int>("amount") ?: throw IllegalArgumentException("amount required")
                val cardId = call.argument<String>("cardId") ?: throw IllegalArgumentException("cardId required")
                
                // Simulate Toss API call
                delay(1000)
                
                val transactionId = "TOSS_${generateTransactionId()}"
                
                val response = mapOf(
                    "success" to true,
                    "transactionId" to transactionId,
                    "amount" to amount
                )
                
                result.success(response)
            } catch (e: Exception) {
                result.error("TOSS_TRANSFER_ERROR", e.message, null)
            }
        }
    }

    private fun processKakaoPayTransfer(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val amount = call.argument<Int>("amount") ?: throw IllegalArgumentException("amount required")
                val cardId = call.argument<String>("cardId") ?: throw IllegalArgumentException("cardId required")
                
                // Simulate KakaoPay API call
                delay(1000)
                
                val transactionId = "KAKAO_${generateTransactionId()}"
                
                val response = mapOf(
                    "success" to true,
                    "transactionId" to transactionId,
                    "amount" to amount
                )
                
                result.success(response)
            } catch (e: Exception) {
                result.error("KAKAOPAY_TRANSFER_ERROR", e.message, null)
            }
        }
    }

    private fun processNaverPayTransfer(call: MethodCall, result: Result) {
        mainScope.launch {
            try {
                val amount = call.argument<Int>("amount") ?: throw IllegalArgumentException("amount required")
                val cardId = call.argument<String>("cardId") ?: throw IllegalArgumentException("cardId required")
                
                // Simulate NaverPay API call
                delay(1000)
                
                val transactionId = "NAVER_${generateTransactionId()}"
                
                val response = mapOf(
                    "success" to true,
                    "transactionId" to transactionId,
                    "amount" to amount
                )
                
                result.success(response)
            } catch (e: Exception) {
                result.error("NAVERPAY_TRANSFER_ERROR", e.message, null)
            }
        }
    }

    private fun initializeMockData() {
        // Initialize mock bank accounts for testing
        mockAccounts["KB:123456789012"] = BankAccount(
            bank = "KB",
            account = "123456789012",
            holder = "홍길동",
            balance = 50000,
            hashedPin = hashPin("1234")
        )
        
        mockAccounts["SHINHAN:987654321098"] = BankAccount(
            bank = "SHINHAN",
            account = "987654321098",
            holder = "홍길동",
            balance = 100000,
            hashedPin = hashPin("1234")
        )
    }

    private fun generateVirtualAccountNumber(): String {
        val random = Random()
        return buildString {
            repeat(14) {
                append(random.nextInt(10))
            }
        }
    }

    private fun generateTransactionId(): String {
        return "TXN_${System.currentTimeMillis()}_${Random().nextInt(10000)}"
    }

    private fun hashPin(pin: String): String {
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(pin.toByteArray())
        return digest.fold("") { str, it -> str + "%02x".format(it) }
    }

    private fun verifyPin(inputPin: String, hashedPin: String): Boolean {
        return hashPin(inputPin) == hashedPin
    }

    // Data classes
    data class BankAccount(
        val bank: String,
        val account: String,
        val holder: String,
        var balance: Int,
        val hashedPin: String
    )

    data class VirtualAccount(
        val accountNumber: String,
        val bankName: String,
        val bankCode: String,
        val amount: Int,
        val expireAt: Date,
        val depositorName: String,
        val userId: String,
        val cardType: String,
        val cardNumber: String
    )

    data class TransactionRecord(
        val transactionId: String,
        val fromBank: String,
        val fromAccount: String,
        val amount: Int,
        val timestamp: Date,
        val cardId: String,
        val status: String
    )
}