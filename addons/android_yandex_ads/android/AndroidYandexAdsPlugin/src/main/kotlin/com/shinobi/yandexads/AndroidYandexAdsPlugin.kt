package com.shinobi.yandexads

import android.app.Activity
import android.util.Log
import com.yandex.mobile.ads.common.AdRequestConfiguration
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.common.ImpressionData
import com.yandex.mobile.ads.common.MobileAds
import com.yandex.mobile.ads.interstitial.InterstitialAd
import com.yandex.mobile.ads.interstitial.InterstitialAdEventListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoadListener
import com.yandex.mobile.ads.interstitial.InterstitialAdLoader
import com.yandex.mobile.ads.rewarded.Reward
import com.yandex.mobile.ads.rewarded.RewardedAd
import com.yandex.mobile.ads.rewarded.RewardedAdEventListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoadListener
import com.yandex.mobile.ads.rewarded.RewardedAdLoader
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot 4 Android Plugin v2 bridge for Yandex Mobile Ads SDK.
 *
 * Exposed as Engine.get_singleton("AndroidYandexAds") in GDScript.
 * All ad rewards are handled exclusively on the GDScript side; this plugin
 * only emits signals — it never modifies gameplay state.
 *
 * Signal contract (mirrors PlatformServices.gd):
 *   rewarded_ad_opened          — ad overlay appeared
 *   rewarded_ad_rewarded        — user earned the reward (fires before dismissed)
 *   rewarded_ad_closed(bool)    — ad dismissed; bool = whether reward was earned
 *   rewarded_ad_error(String)   — load or show failure
 *   fullscreen_ad_opened        — interstitial overlay appeared
 *   fullscreen_ad_closed        — interstitial dismissed after being shown
 *   fullscreen_ad_error(String) — load or show failure
 */
class AndroidYandexAdsPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "AndroidYandexAds"
    }

    // ── State ─────────────────────────────────────────────────────────────────

    @Volatile
    private var sdkInitialized = false

    // Rewarded ad — one at a time
    private var rewardedAdLoader: RewardedAdLoader? = null
    private var rewardedAd: RewardedAd? = null
    private var rewardGranted = false

    // Interstitial ad — one at a time
    private var interstitialAdLoader: InterstitialAdLoader? = null
    private var interstitialAd: InterstitialAd? = null

    // ── GodotPlugin API ───────────────────────────────────────────────────────

    override fun getPluginName(): String = "AndroidYandexAds"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("rewarded_ad_opened"),
        SignalInfo("rewarded_ad_rewarded"),
        SignalInfo("rewarded_ad_closed", Boolean::class.javaObjectType),
        SignalInfo("rewarded_ad_error", String::class.java),
        SignalInfo("fullscreen_ad_opened"),
        SignalInfo("fullscreen_ad_closed"),
        SignalInfo("fullscreen_ad_error", String::class.java),
    )

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    /**
     * Initialize the Yandex Mobile Ads SDK.
     * Call once at game startup (e.g., from AndroidRuStorePlatform._ready()).
     * Safe to call more than once — subsequent calls are no-ops.
     */
    @UsedByGodot
    fun initialize() {
        if (sdkInitialized) return
        val activity: Activity = getActivity() ?: run {
            Log.e(TAG, "initialize: activity is null")
            return
        }
        activity.runOnUiThread {
            Log.d(TAG, "Yandex Mobile Ads SDK initialization started")
            MobileAds.initialize(activity) {
                sdkInitialized = true
                Log.d(TAG, "Yandex Mobile Ads SDK initialized successfully")
            }
        }
    }

    /** Returns true — the plugin is present and compiled. */
    @UsedByGodot
    fun is_available(): Boolean = true

    /** Returns true after initialize() callback fires. */
    @UsedByGodot
    fun is_initialized(): Boolean = sdkInitialized

    // ── Rewarded ads ──────────────────────────────────────────────────────────

    /**
     * Load and show a rewarded ad for the given Yandex ad unit id.
     * Results arrive via rewarded_ad_* signals.
     * Gameplay reward must be granted only on rewarded_ad_rewarded signal in GDScript.
     */
    @UsedByGodot
    fun show_rewarded_ad(adUnitId: String) {
        val activity: Activity = getActivity() ?: run {
            Log.e(TAG, "show_rewarded_ad: activity is null")
            emitSignal("rewarded_ad_error", "Activity not available")
            return
        }

        rewardGranted = false

        activity.runOnUiThread {
            Log.d(TAG, "Loading rewarded ad: $adUnitId")
            val loader = RewardedAdLoader(activity).also { rewardedAdLoader = it }

            loader.setAdLoadListener(object : RewardedAdLoadListener {
                override fun onAdLoaded(ad: RewardedAd) {
                    rewardedAd = ad
                    ad.setAdEventListener(object : RewardedAdEventListener {
                        override fun onAdShown() {
                            Log.d(TAG, "Rewarded ad shown")
                            emitSignal("rewarded_ad_opened")
                        }

                        override fun onAdFailedToShow(error: AdRequestError) {
                            Log.e(TAG, "Rewarded ad failed to show: ${error.description}")
                            rewardedAd = null
                            emitSignal("rewarded_ad_error", "Failed to show: ${error.description}")
                        }

                        override fun onAdDismissed() {
                            Log.d(TAG, "Rewarded ad dismissed, reward granted: $rewardGranted")
                            val wasRewarded = rewardGranted
                            rewardedAd = null
                            emitSignal("rewarded_ad_closed", wasRewarded)
                        }

                        override fun onAdClicked() {}

                        override fun onAdImpression(data: ImpressionData?) {}

                        override fun onRewarded(reward: Reward) {
                            Log.d(TAG, "Rewarded ad reward earned: ${reward.type} x${reward.amount}")
                            rewardGranted = true
                            emitSignal("rewarded_ad_rewarded")
                        }
                    })
                    Log.d(TAG, "Rewarded ad loaded, showing")
                    ad.show(activity)
                }

                override fun onAdFailedToLoad(error: AdRequestError) {
                    Log.e(TAG, "Rewarded ad failed to load: ${error.description} (code ${error.code})")
                    rewardedAd = null
                    emitSignal("rewarded_ad_error", "Failed to load: ${error.description}")
                }
            })

            loader.loadAd(AdRequestConfiguration.Builder(adUnitId).build())
        }
    }

    // ── Interstitial (fullscreen) ads ─────────────────────────────────────────

    /**
     * Load and show an interstitial ad for the given Yandex ad unit id.
     * Results arrive via fullscreen_ad_* signals.
     * No reward is granted for interstitial ads.
     */
    @UsedByGodot
    fun show_interstitial_ad(adUnitId: String) {
        val activity: Activity = getActivity() ?: run {
            Log.e(TAG, "show_interstitial_ad: activity is null")
            emitSignal("fullscreen_ad_error", "Activity not available")
            return
        }

        activity.runOnUiThread {
            Log.d(TAG, "Loading interstitial ad: $adUnitId")
            val loader = InterstitialAdLoader(activity).also { interstitialAdLoader = it }

            loader.setAdLoadListener(object : InterstitialAdLoadListener {
                override fun onAdLoaded(ad: InterstitialAd) {
                    interstitialAd = ad
                    ad.setAdEventListener(object : InterstitialAdEventListener {
                        override fun onAdShown() {
                            Log.d(TAG, "Interstitial ad shown")
                            emitSignal("fullscreen_ad_opened")
                        }

                        override fun onAdFailedToShow(error: AdRequestError) {
                            Log.e(TAG, "Interstitial ad failed to show: ${error.description}")
                            interstitialAd = null
                            emitSignal("fullscreen_ad_error", "Failed to show: ${error.description}")
                        }

                        override fun onAdDismissed() {
                            Log.d(TAG, "Interstitial ad dismissed")
                            interstitialAd = null
                            emitSignal("fullscreen_ad_closed")
                        }

                        override fun onAdClicked() {}

                        override fun onAdImpression(data: ImpressionData?) {}
                    })
                    Log.d(TAG, "Interstitial ad loaded, showing")
                    ad.show(activity)
                }

                override fun onAdFailedToLoad(error: AdRequestError) {
                    Log.e(TAG, "Interstitial ad failed to load: ${error.description} (code ${error.code})")
                    interstitialAd = null
                    emitSignal("fullscreen_ad_error", "Failed to load: ${error.description}")
                }
            })

            loader.loadAd(AdRequestConfiguration.Builder(adUnitId).build())
        }
    }
}
