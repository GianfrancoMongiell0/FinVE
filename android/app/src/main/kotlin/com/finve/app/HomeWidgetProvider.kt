package com.finve.finve_new

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        // Determine widget size from options
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)

        val layoutId = when {
            minWidth >= 250 -> R.layout.widget_large
            minWidth >= 130 -> R.layout.widget_medium
            else -> R.layout.widget_small
        }

        val views = RemoteViews(context.packageName, layoutId)

        // ── Common data ───────────────────────
        val totalUsd = widgetData.getString("widget_total_usd", "\$0.00") ?: "\$0.00"
        val lastUpdated = widgetData.getString("widget_last_updated", "—") ?: "—"
        val bcvRate = widgetData.getString("widget_bcv_rate", "—") ?: "—"
        val parallelRate = widgetData.getString("widget_parallel_rate", "—") ?: "—"

        // ── Small widget ──────────────────────
        if (layoutId == R.layout.widget_small) {
            views.setTextViewText(R.id.widget_small_total, totalUsd)
            views.setTextViewText(R.id.widget_small_updated, "Actualizado $lastUpdated")
        }

        // ── Medium widget ─────────────────────
        if (layoutId == R.layout.widget_medium) {
            views.setTextViewText(R.id.widget_medium_total, totalUsd)

            val walletCount = widgetData.getInt("wallet_count", 0)
            for (i in 0..3) {
                val name = widgetData.getString("wallet_${i}_name", "") ?: ""
                val balance = widgetData.getString("wallet_${i}_balance", "") ?: ""
                if (name.isEmpty()) {
                    // Hide unused rows (set empty)
                    views.setTextViewText(
                        getWalletNameViewId(i), ""
                    )
                    views.setTextViewText(
                        getWalletBalanceViewId(i), ""
                    )
                } else {
                    views.setTextViewText(getWalletNameViewId(i), name)
                    views.setTextViewText(getWalletBalanceViewId(i), balance)
                }
            }
        }

        // ── Large widget ──────────────────────
        if (layoutId == R.layout.widget_large) {
            views.setTextViewText(R.id.widget_large_total, totalUsd)
            views.setTextViewText(R.id.widget_large_bcv, "BCV: $bcvRate")
            views.setTextViewText(R.id.widget_large_parallel, "Paralelo: $parallelRate")
            views.setTextViewText(R.id.widget_large_updated, lastUpdated)

            // Last 3 transactions
            for (i in 0..2) {
                val icon = widgetData.getString("tx_${i}_icon", "") ?: ""
                val amount = widgetData.getString("tx_${i}_amount", "") ?: ""
                val category = widgetData.getString("tx_${i}_category", "") ?: ""

                if (icon.isEmpty()) continue

                views.setTextViewText(getTxIconViewId(i), icon)
                views.setTextViewText(getTxAmountViewId(i), amount)
                views.setTextViewText(getTxCategoryViewId(i), category)
            }
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getWalletNameViewId(index: Int): Int = when (index) {
        0 -> R.id.wallet_0_name
        1 -> R.id.wallet_1_name
        2 -> R.id.wallet_2_name
        else -> R.id.wallet_3_name
    }

    private fun getWalletBalanceViewId(index: Int): Int = when (index) {
        0 -> R.id.wallet_0_balance
        1 -> R.id.wallet_1_balance
        2 -> R.id.wallet_2_balance
        else -> R.id.wallet_3_balance
    }

    private fun getTxIconViewId(index: Int): Int = when (index) {
        0 -> R.id.tx_0_icon
        1 -> R.id.tx_1_icon
        else -> R.id.tx_2_icon
    }

    private fun getTxAmountViewId(index: Int): Int = when (index) {
        0 -> R.id.tx_0_amount
        1 -> R.id.tx_1_amount
        else -> R.id.tx_2_amount
    }

    private fun getTxCategoryViewId(index: Int): Int = when (index) {
        0 -> R.id.tx_0_category
        1 -> R.id.tx_1_category
        else -> R.id.tx_2_category
    }
}