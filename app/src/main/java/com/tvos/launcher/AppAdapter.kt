package com.tvos.launcher

import android.content.Intent
import android.graphics.drawable.Drawable
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

data class AppItem(
    val packageName: String,
    val label: String,
    val icon: Drawable,
    val intent: Intent,
    val tv: Boolean,
)

class AppAdapter(
    private val onClick: (AppItem) -> Unit,
    private val onLongClick: (AppItem) -> Unit,
) : RecyclerView.Adapter<AppAdapter.VH>() {

    private var items: List<AppItem> = emptyList()

    fun submit(list: List<AppItem>) {
        items = list
        notifyDataSetChanged()
    }

    class VH(view: View) : RecyclerView.ViewHolder(view) {
        val tile: View = view.findViewById(R.id.tile)
        val icon: ImageView = view.findViewById(R.id.icon)
        val label: TextView = view.findViewById(R.id.label)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH =
        VH(LayoutInflater.from(parent.context).inflate(R.layout.item_app, parent, false))

    override fun onBindViewHolder(holder: VH, position: Int) {
        val item = items[position]
        holder.icon.setImageDrawable(item.icon)
        holder.label.text = item.label

        holder.itemView.setOnClickListener { onClick(item) }
        holder.itemView.setOnLongClickListener {
            onLongClick(item)
            true
        }
        holder.itemView.setOnFocusChangeListener { _, focused ->
            val scale = if (focused) 1.14f else 1f
            holder.tile.animate().scaleX(scale).scaleY(scale).setDuration(110).start()
            holder.label.animate().alpha(if (focused) 1f else 0f).setDuration(110).start()
        }
    }

    override fun onViewRecycled(holder: VH) {
        holder.tile.animate().cancel()
        holder.label.animate().cancel()
        holder.tile.scaleX = 1f
        holder.tile.scaleY = 1f
        holder.label.alpha = 0f
    }

    override fun getItemCount(): Int = items.size
}
