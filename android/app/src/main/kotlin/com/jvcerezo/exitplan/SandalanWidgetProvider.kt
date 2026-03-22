package com.jvcerezo.exitplan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.content.Intent
import android.net.Uri
import android.app.PendingIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SandalanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.sandalan_widget)

            // Read data from SharedPreferences (set by Flutter)
            val todaySpending = widgetData.getString("today_spending", "\u20B10.00")
            val streak = widgetData.getInt("streak_count", 0)

            views.setTextViewText(R.id.today_amount, todaySpending)
            views.setTextViewText(R.id.streak_text, "\uD83D\uDD25 $streak")

            // Set click intents
            val expenseIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("sandalan://quick-add/expense")
            }
            views.setOnClickPendingIntent(
                R.id.btn_expense,
                PendingIntent.getActivity(
                    context, 0, expenseIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            val incomeIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("sandalan://quick-add/income")
            }
            views.setOnClickPendingIntent(
                R.id.btn_income,
                PendingIntent.getActivity(
                    context, 1, incomeIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
