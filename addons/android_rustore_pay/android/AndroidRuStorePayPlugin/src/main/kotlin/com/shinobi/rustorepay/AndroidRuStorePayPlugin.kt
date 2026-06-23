package com.shinobi.rustorepay

import android.util.Log
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot 4 Android Plugin v2 — compile-safe adapter for the RuStore Pay SDK.
 *
 * Exposed as Engine.get_singleton("AndroidRuStorePay") in GDScript.
 *
 * THIS IS A STUB. All SDK call sites are marked TODO. The plugin compiles and
 * runs without the RuStore Pay SDK present — all methods emit the appropriate
 * error or no-op signal so the GDScript layer degrades gracefully.
 *
 * To complete the integration:
 *   1. Obtain the official RuStore Pay SDK AAR from RuStore developer docs.
 *   2. Add the AAR (or Maven coordinate) to build.gradle — see the TODO there.
 *   3. Replace each "TODO: SDK call" block below with the real SDK API.
 *   4. Rebuild: ./gradlew assembleRelease
 *   See docs/rustore_pay_integration.md for the full checklist.
 *
 * Signal contract (mirrors PlatformServices.gd / AndroidRuStorePlatform.gd):
 *   purchase_success(productId: String, purchaseToken: String)
 *       — purchase completed; purchaseToken is used for consume and dedup
 *   purchase_cancelled
 *       — user cancelled the purchase UI
 *   purchase_error(message: String)
 *       — purchase failed or SDK error
 *   pending_purchase_found(productId: String, purchaseToken: String)
 *       — an unfinished purchase from a previous session was found
 *   pending_purchases_check_completed
 *       — get_pending_purchases() finished with no pending items
 *   pending_purchases_check_error(message: String)
 *       — get_pending_purchases() failed
 */
class AndroidRuStorePayPlugin(godot: Godot) : GodotPlugin(godot) {

    companion object {
        private const val TAG = "AndroidRuStorePay"
    }

    // ── GodotPlugin API ───────────────────────────────────────────────────────

    override fun getPluginName(): String = "AndroidRuStorePay"

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("purchase_success", String::class.java, String::class.java),
        SignalInfo("purchase_cancelled"),
        SignalInfo("purchase_error", String::class.java),
        SignalInfo("pending_purchase_found", String::class.java, String::class.java),
        SignalInfo("pending_purchases_check_completed"),
        SignalInfo("pending_purchases_check_error", String::class.java),
    )

    // ── Methods exposed to GDScript ───────────────────────────────────────────

    /**
     * Start a purchase flow for the given RuStore product id.
     * On success emits purchase_success(productId, purchaseToken).
     * On cancel emits purchase_cancelled.
     * On error emits purchase_error(message).
     */
    @UsedByGodot
    fun purchase(productId: String) {
        Log.d(TAG, "purchase called for productId=$productId")
        val activity = getActivity() ?: run {
            Log.e(TAG, "purchase: activity is null")
            emitSignal("purchase_error", "Activity not available")
            return
        }
        activity.runOnUiThread {
            // TODO: Replace this block with the real RuStore Pay SDK call.
            // Consult the official RuStore Pay SDK documentation for the exact
            // class names and method signatures. Do NOT guess or invent names.
            // Example pattern (verify against real docs before using):
            //
            //   val client = <RuStorePayClientClass>.getInstance()
            //   client.purchase(productId,
            //       onSuccess = { purchase ->
            //           emitSignal("purchase_success", purchase.productId, purchase.purchaseId)
            //       },
            //       onCancelled = {
            //           emitSignal("purchase_cancelled")
            //       },
            //       onFailure = { error ->
            //           emitSignal("purchase_error", error.message ?: "Unknown error")
            //       }
            //   )
            //
            Log.w(TAG, "purchase: RuStore Pay SDK not integrated — emitting error")
            emitSignal("purchase_error", "RuStore Pay SDK not integrated")
        }
    }

    /**
     * Consume (finalize) a purchase by its purchase token (purchaseId in RuStore terms).
     * Must be called after granting the in-app reward so RuStore allows re-purchase.
     * Errors are logged but not signalled — consume failure is non-fatal for the user.
     */
    @UsedByGodot
    fun consume(purchaseToken: String) {
        Log.d(TAG, "consume called for purchaseToken=$purchaseToken")
        val activity = getActivity() ?: run {
            Log.e(TAG, "consume: activity is null")
            return
        }
        activity.runOnUiThread {
            // TODO: Replace with the real RuStore Pay SDK consume call.
            // Example pattern (verify against real docs before using):
            //
            //   val client = <RuStorePayClientClass>.getInstance()
            //   client.confirmPurchase(purchaseToken,
            //       onSuccess = { Log.d(TAG, "consume success: $purchaseToken") },
            //       onFailure = { error -> Log.e(TAG, "consume failed: ${error.message}") }
            //   )
            //
            Log.w(TAG, "consume: RuStore Pay SDK not integrated — skipping")
        }
    }

    /**
     * Query RuStore for purchases that were completed but not yet consumed.
     * For each found purchase emits pending_purchase_found(productId, purchaseToken).
     * When the list is exhausted (or empty) emits pending_purchases_check_completed.
     * On SDK error emits pending_purchases_check_error(message).
     */
    @UsedByGodot
    fun get_pending_purchases() {
        Log.d(TAG, "get_pending_purchases called")
        val activity = getActivity() ?: run {
            Log.e(TAG, "get_pending_purchases: activity is null")
            emitSignal("pending_purchases_check_error", "Activity not available")
            return
        }
        activity.runOnUiThread {
            // TODO: Replace with the real RuStore Pay SDK getPurchases call.
            // For each unconsumed purchase in the response, emit:
            //   emitSignal("pending_purchase_found", purchase.productId, purchase.purchaseId)
            // After iterating all purchases, emit:
            //   emitSignal("pending_purchases_check_completed")
            // On error, emit:
            //   emitSignal("pending_purchases_check_error", error.message ?: "Unknown")
            //
            // Example pattern (verify against real docs before using):
            //
            //   val client = <RuStorePayClientClass>.getInstance()
            //   client.getPurchases(
            //       onSuccess = { purchases ->
            //           purchases.forEach { p ->
            //               emitSignal("pending_purchase_found", p.productId, p.purchaseId)
            //           }
            //           emitSignal("pending_purchases_check_completed")
            //       },
            //       onFailure = { error ->
            //           emitSignal("pending_purchases_check_error", error.message ?: "Unknown")
            //       }
            //   )
            //
            Log.w(TAG, "get_pending_purchases: RuStore Pay SDK not integrated — emitting completed")
            emitSignal("pending_purchases_check_completed")
        }
    }

    /** Returns true — the plugin is present and compiled. */
    @UsedByGodot
    fun is_available(): Boolean = true
}
