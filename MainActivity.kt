package com.tvos.launcher

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import java.util.concurrent.Executors

/**
 * Ecrã inicial leve ao estilo iOS: grelha de ícones arredondados com nome,
 * dock em baixo, relógio e fundo em gradiente. Sem blur nem serviços em segundo plano.
 */
class MainActivity : Activity() {

    private val io = Executors.newSingleThreadExecutor()
    private lateinit var list: RecyclerView
    private lateinit var dock: RecyclerView
    private lateinit var gridAdapter: AppAdapter
    private lateinit var dockAdapter: AppAdapter

    /** Apps que, se estiverem instaladas, vão para o dock (por esta ordem). */
    private val dockPackages = listOf(
        "com.netflix.ninja",
        "com.google.android.youtube.tv",
        "com.amazon.amazonvideo.livingroom",
        "com.disney.disneyplus",
        "com.spotify.tv.android",
    )

    private val settingsPackages = setOf("com.android.tv.settings", "com.android.settings")

    private val packageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            loadApps()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        gridAdapter = AppAdapter(R.layout.item_app, { launch(it) }, { openAppInfo(it) })
        dockAdapter = AppAdapter(R.layout.item_dock, { launch(it) }, { openAppInfo(it) })

        val span = ((resources.configuration.screenWidthDp - 96) / 128).coerceIn(5, 8)
        list = findViewById(R.id.apps)
        list.layoutManager = GridLayoutManager(this, span)
        list.adapter = gridAdapter
        list.itemAnimator = null
        list.setItemViewCacheSize(24)

        dock = findViewById(R.id.dock)
        dock.layoutManager = LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false)
        dock.adapter = dockAdapter
        dock.itemAnimator = null

        loadApps()
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_CHANGED)
            addDataScheme("package")
        }
        ContextCompat.registerReceiver(this, packageReceiver, filter, ContextCompat.RECEIVER_EXPORTED)
    }

    override fun onStop() {
        super.onStop()
        try {
            unregisterReceiver(packageReceiver)
        } catch (_: IllegalArgumentException) {
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        io.shutdown()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        // Carregar em Home volta ao início da grelha.
        list.scrollToPosition(0)
        focusFirst()
    }

    @Suppress("OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        // Um launcher não deve fechar com o botão Voltar.
    }

    @Suppress("DEPRECATION")
    private fun loadApps() {
        io.execute {
            val pm = packageManager
            fun query(category: String) =
                pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(category), 0)

            val tv = query(Intent.CATEGORY_LEANBACK_LAUNCHER)
            val tvPackages = tv.map { it.activityInfo.packageName }.toSet()

            val all = (tv + query(Intent.CATEGORY_LAUNCHER))
                .filter { it.activityInfo.packageName != packageName }
                .distinctBy { it.activityInfo.packageName }
                .map { ri ->
                    val ai = ri.activityInfo
                    AppItem(
                        packageName = ai.packageName,
                        label = ri.loadLabel(pm).toString(),
                        icon = ri.loadIcon(pm),
                        intent = Intent(Intent.ACTION_MAIN)
                            .setClassName(ai.packageName, ai.name)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED),
                        tv = ai.packageName in tvPackages,
                    )
                }
                .sortedWith(compareBy<AppItem>({ !it.tv }, { it.label.lowercase() }))

            // O dock tem sempre as Definições, para nunca ficares sem acesso a elas.
            val dockItems = dockPackages.mapNotNull { pkg -> all.firstOrNull { it.packageName == pkg } } + settingsItem()
            val dockNames = dockItems.map { it.packageName }.toSet()
            val gridItems = all.filter { it.packageName !in dockNames && it.packageName !in settingsPackages }

            runOnUiThread {
                if (!isDestroyed) {
                    gridAdapter.submit(gridItems)
                    dockAdapter.submit(dockItems)
                    focusFirst()
                }
            }
        }
    }

    private fun settingsItem() = AppItem(
        packageName = "com.android.tv.settings",
        label = "Definições",
        icon = ContextCompat.getDrawable(this, R.drawable.ic_settings)!!,
        intent = Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        tv = true,
    )

    private fun focusFirst() {
        list.post {
            if (list.focusedChild == null && dock.focusedChild == null) {
                (list.getChildAt(0) ?: dock.getChildAt(0))?.requestFocus()
            }
        }
    }

    private fun launch(item: AppItem) {
        try {
            startActivity(item.intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Não foi possível abrir ${item.label}", Toast.LENGTH_SHORT).show()
        }
    }

    /** Manter OK premido abre a página da app (aí podes desinstalar ou limpar a cache). */
    private fun openAppInfo(item: AppItem) {
        try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${item.packageName}"))
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: Exception) {
            Toast.makeText(this, "Página da app indisponível", Toast.LENGTH_SHORT).show()
        }
    }
}
