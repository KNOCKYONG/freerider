package com.freerider

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.samsung.android.sdk.samsungpay.v2.SamsungPay
import com.samsung.android.sdk.samsungpay.v2.StatusListener
import com.samsung.android.sdk.samsungpay.v2.payment.*
import com.samsung.android.sdk.samsungpay.v2.card.*

class MobilePayPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var samsungPay: SamsungPay
    private val PARTNER_SERVICE_TYPE = SamsungPay.ServiceType.INAPP_PAYMENT
    
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.freerider.payment/mobile_pay")
        channel.setMethodCallHandler(this)
        
        // Samsung Pay SDK 초기화
        val bundle = Bundle()
        bundle.putString(SamsungPay.PARTNER_SERVICE_TYPE, PARTNER_SERVICE_TYPE.toString())
        
        val partnerInfo = PartnerInfo(
            "freerider_service_id", // 실제 서비스 ID로 교체 필요
            bundle
        )
        
        samsungPay = SamsungPay(binding.applicationContext, partnerInfo)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isSamsungPayAvailable" -> checkSamsungPayAvailability(result)
            "processSamsungPayment" -> processSamsungPayment(call, result)
            "getSamsungPayCards" -> getSamsungPayCards(result)
            "chargeNFCCard" -> chargeNFCCard(call, result)
            else -> result.notImplemented()
        }
    }

    private fun checkSamsungPayAvailability(result: Result) {
        samsungPay.getSamsungPayStatus(object : StatusListener {
            override fun onSuccess(status: Int, bundle: Bundle) {
                when (status) {
                    SamsungPay.SPAY_READY -> result.success(true)
                    SamsungPay.SPAY_NOT_SUPPORTED -> result.success(false)
                    SamsungPay.SPAY_NOT_READY -> {
                        // Samsung Pay 활성화 필요
                        samsungPay.activateSamsungPay()
                        result.success(false)
                    }
                    else -> result.success(false)
                }
            }

            override fun onFail(errorCode: Int, bundle: Bundle) {
                result.success(false)
            }
        })
    }

    private fun processSamsungPayment(call: MethodCall, result: Result) {
        val merchantName = call.argument<String>("merchantName") ?: "FREERIDER"
        val amount = call.argument<String>("amount") ?: "0"
        val orderNumber = call.argument<String>("orderNumber") ?: ""
        val cardType = call.argument<String>("cardType") ?: "T-money"
        
        val paymentInfo = PaymentInfo.Builder()
            .setMerchantId("freerider_merchant_id")
            .setMerchantName(merchantName)
            .setOrderNumber(orderNumber)
            .setPaymentProtocol(PaymentInfo.PaymentProtocol.PROTOCOL_3DS)
            .setAddressInPaymentSheet(PaymentInfo.AddressInPaymentSheet.DO_NOT_SHOW)
            .setAllowedCardBrands(getAllowedCardBrands())
            .setCardInfo(getCardInfo(cardType))
            .setPaymentType(PaymentInfo.PaymentType.SINGLE_PAYMENT)
            .setAmount(PaymentInfo.Amount("KRW", amount))
            .build()
        
        val transactionListener = object : PaymentManager.TransactionListener {
            override fun onSuccess(response: CustomSheetPaymentInfo, 
                                  paymentCredential: String, 
                                  extraPaymentData: Bundle) {
                // 결제 성공
                val resultMap = hashMapOf(
                    "success" to true,
                    "transactionId" to response.orderNumber,
                    "paymentCredential" to paymentCredential
                )
                result.success(resultMap)
            }

            override fun onFailure(errorCode: Int, errorData: Bundle?) {
                // 결제 실패
                val resultMap = hashMapOf(
                    "success" to false,
                    "error" to "Payment failed with code: $errorCode"
                )
                result.success(resultMap)
            }
        }
        
        val paymentManager = PaymentManager(activity!!, PARTNER_SERVICE_TYPE)
        paymentManager.startInAppPayWithCustomSheet(paymentInfo, transactionListener)
    }

    private fun getSamsungPayCards(result: Result) {
        val cardManager = CardManager(activity!!, PARTNER_SERVICE_TYPE)
        
        cardManager.getAllCards(null, object : GetCardListener {
            override fun onSuccess(cards: List<Card>) {
                val cardList = cards.map { card ->
                    hashMapOf(
                        "id" to card.cardId,
                        "type" to detectCardType(card),
                        "lastFourDigits" to card.cardInfo?.getString("last4Digits"),
                        "balance" to 0, // 실제 잔액 조회 API 필요
                        "isDefault" to card.isDefaultCard
                    )
                }
                result.success(cardList)
            }

            override fun onFail(errorCode: Int, errorData: Bundle?) {
                result.success(emptyList<Map<String, Any>>())
            }
        })
    }

    private fun chargeNFCCard(call: MethodCall, result: Result) {
        // NFC 카드 충전 로직 구현
        // 실제 구현 시 NFC API와 교통카드 충전 프로토콜 필요
        val cardNumber = call.argument<String>("cardNumber") ?: ""
        val amount = call.argument<Int>("amount") ?: 0
        
        // 시뮬레이션
        val resultMap = hashMapOf(
            "success" to true,
            "transactionId" to "NFC${System.currentTimeMillis()}",
            "newBalance" to (5000 + amount) // 예시 잔액
        )
        result.success(resultMap)
    }

    private fun getAllowedCardBrands(): List<PaymentInfo.Brand> {
        return listOf(
            PaymentInfo.Brand.VISA,
            PaymentInfo.Brand.MASTERCARD,
            PaymentInfo.Brand.AMERICANEXPRESS
        )
    }

    private fun getCardInfo(cardType: String): PaymentInfo.CardInfo {
        // 교통카드 타입에 따른 카드 정보 설정
        return PaymentInfo.CardInfo.Builder()
            .setCardBrand(PaymentInfo.Brand.VISA) // 실제 카드 브랜드로 교체
            .build()
    }

    private fun detectCardType(card: Card): String {
        // 카드 타입 감지 로직
        val cardBrand = card.cardInfo?.getString("cardBrand") ?: ""
        return when {
            cardBrand.contains("tmoney", ignoreCase = true) -> "T-money"
            cardBrand.contains("cashbee", ignoreCase = true) -> "Cashbee"
            else -> "Unknown"
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}