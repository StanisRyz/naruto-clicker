package com.godot.game;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

/**
 * Trampoline activity for RuStore Pay deeplink callbacks.
 *
 * RuStore Pay SDK redirects the purchase result to this activity via the custom
 * URL scheme declared in AndroidManifest.xml. This activity forwards the intent
 * to GodotApp (FLAG_ACTIVITY_SINGLE_TOP so no new instance is created) and
 * immediately finishes. GodotActivity.onNewIntent picks up the intent, and the
 * RuStore Pay SDK processes the payment result from there.
 */
public class RuStoreIntentFilterActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = new Intent(this, GodotApp.class);
        intent.setData(getIntent().getData());
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(intent);
        finish();
    }
}
