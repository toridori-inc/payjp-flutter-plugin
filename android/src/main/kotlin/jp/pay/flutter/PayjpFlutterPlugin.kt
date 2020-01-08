package jp.pay.flutter

import androidx.core.os.LocaleListCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import jp.pay.android.Payjp
import jp.pay.android.PayjpConfiguration
import jp.pay.android.model.TenantId
import java.util.Locale

class PayjpFlutterPlugin(
  register: Registrar,
  channel: MethodChannel
) : MethodCallHandler {
  companion object {
    private const val CHANNEL_NAME = "payjp"
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
      channel.setMethodCallHandler(PayjpFlutterPlugin(registrar, channel))
    }
  }

  private val cardFormModule = CardFormModule(register, channel)

  override fun onMethodCall(call: MethodCall, result: Result) = when (call.method) {
    ChannelContracts.CONFIGURE -> {
      val publicKey = checkNotNull(call.argument<String>("publicKey"))
      val debugEnabled = call.argument<Boolean>("debugEnabled") ?: false
      val locale = call.argument<String>("locale")?.let { tag ->
        LocaleListCompat.forLanguageTags(tag).takeIf { it.size() > 0 }?.get(0)
      } ?: Locale.getDefault()
      Payjp.init(PayjpConfiguration.Builder(publicKey = publicKey)
        .setDebugEnabled(debugEnabled)
        .setTokenBackgroundHandler(cardFormModule)
        .setLocale(locale)
        .build())
      result.success(null)
    }
    ChannelContracts.START_CARD_FORM -> {
      val tenantId = call.argument<String>("tenantId")?.let { TenantId(it) }
      cardFormModule.startCardForm(result, tenantId)
    }
    ChannelContracts.SHOW_TOKEN_PROCESSING_ERROR -> {
      val message = checkNotNull(call.argument<String>("message"))
      cardFormModule.showTokenProcessingError(result, message)
    }
    ChannelContracts.COMPLETE_CARD_FORM -> {
      cardFormModule.completeCardForm(result)
    }
    else -> result.notImplemented()
  }
}
