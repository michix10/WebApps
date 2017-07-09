package com.tobykurien.webapps.fragment

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.support.v4.app.DialogFragment
import android.support.v7.app.AlertDialog
import android.util.Log
import com.tobykurien.webapps.R
import com.tobykurien.webapps.activity.WebAppActivity
import org.xtendroid.annotations.AndroidDialogFragment
import java.net.*
import java.io.*
import android.app.ProgressDialog

import static extension org.xtendroid.utils.AsyncBuilder.*
import static extension org.xtendroid.utils.AlertUtils.*

/**
 * Dialog to open a URL.
 */
@AndroidDialogFragment(R.layout.dlg_open_url) class DlgOpenUrl extends DialogFragment {

	/**
	 * Create a dialog using the AlertDialog Builder, but our custom layout
	 */
	override onCreateDialog(Bundle instance) {
		new AlertDialog.Builder(activity)
			.setTitle(R.string.open_site)
			.setView(contentView) // contentView is the layout specified in the annotation
			.setPositiveButton(android.R.string.ok, null) // to avoid it closing dialog
			.setNegativeButton(android.R.string.cancel, null)
			.setNeutralButton(R.string.btn_recommended_sites, [
				var link = Uri.parse("https://github.com/tobykurien/WebApps/wiki/Recommended-Webapps")
				openUrl(link);
				dismiss()
			  ])
			.create()
	}

	override onStart() {
		super.onStart()

		val button = (dialog as AlertDialog).getButton(AlertDialog.BUTTON_POSITIVE)
		button.setOnClickListener [
			if (onOpenUrlClick()) {
				dialog.dismiss
			}
		]
	}

	def boolean onOpenUrlClick() {
		var url = txtOpenUrl.text.toString;
		var Uri uri = null
		try {
			if (url.trim().length == 0) throw new Exception();

		    if (url.contains("://")) {
				uri = Uri.parse("https://" + url.substring(url.indexOf("://") + 3))
			} else {
				uri = Uri.parse("https://" + url)
			}
		} catch (Exception e) {
			Log.e("dlgOpenUrl", "Error opening url", e)
			txtOpenUrl.setError(getString(R.string.err_invalid_url), null)
			return false
		}

		// When opening a new URL, let's follow all redirects to get to the final destination
		val originalUri = uri
		val pd = new ProgressDialog(activity)
		pd.setMessage(getString(R.string.progress_opening_site))

		async(pd) [
			var URLConnection con = new URL(originalUri.toString()).openConnection()
			con.connect()
			var InputStream is = con.getInputStream()
			var finalUrl = con.getURL()
			is.close()
			return finalUrl.toString()	
		].then [ result |
			var Uri uriFinal = null
			if (!result.equals(originalUri.toString())) {
				uriFinal = Uri.parse(result)
			} else {
				uriFinal = originalUri
			}

			if (!uriFinal.getScheme().equals("https")) {
				// force it to https
				var builder = uriFinal.buildUpon()
				builder.scheme("https")
				uriFinal = builder.build()
			}

			openUrl(uriFinal)
			dismiss()
		].onError[ Exception error |
			Log.e("dlgOpenUrl", "Error", error)
			toast(error.message)					
		].start()

		return false
	}

	def openUrl(Uri uri) {
		Log.d("openurl", uri.toString())
		var i = new Intent(activity, WebAppActivity)
		i.action = Intent.ACTION_VIEW
		i.data = uri
		startActivity(i)		
	}
}
