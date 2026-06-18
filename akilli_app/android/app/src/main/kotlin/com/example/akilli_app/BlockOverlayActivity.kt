package com.example.akilli_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.ViewGroup

class BlockOverlayActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val blockedPackage = intent.getStringExtra("blocked_package") ?: ""
        val taskName = intent.getStringExtra("task_name") ?: "sua tarefa"

        // Tema transparente por cima
        window.setFlags(
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        )

        // Layout principal
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dpToPx(32), dpToPx(48), dpToPx(32), dpToPx(48))
            
            val bg = GradientDrawable().apply {
                setColor(Color.WHITE)
                cornerRadius = dpToPx(24).toFloat()
            }
            background = bg
        }

        // Fundo escurecido
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#CC000000"))
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(24))
            addView(mainLayout, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ))
        }

        // Ícone de bloqueio
        val iconText = TextView(this).apply {
            text = "🔒"
            textSize = 48f
            gravity = Gravity.CENTER
        }
        mainLayout.addView(iconText)

        // Título
        val title = TextView(this).apply {
            text = "App Bloqueado"
            setTextColor(Color.parseColor("#D32F2F"))
            textSize = 24f
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
            setPadding(0, dpToPx(16), 0, dpToPx(12))
        }
        mainLayout.addView(title)

        // Mensagem
        val message = TextView(this).apply {
            text = "Esse app está bloqueado pelo Modo Foco.\n\n" +
                   "Você deve focar na tarefa \"$taskName\" agora.\n\n" +
                   "Deseja continuar procrastinando e perdendo tempo, " +
                   "mantendo-se neste app que te distrai, ou realizar sua tarefa pendente?"
            setTextColor(Color.parseColor("#424242"))
            textSize = 16f
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
            setPadding(0, 0, 0, dpToPx(24))
        }
        mainLayout.addView(message)

        // Botão "Quero realizar a tarefa" (primário - verde)
        val btnTarefa = Button(this).apply {
            text = "✅ Quero realizar a tarefa e acumular pontos"
            setTextColor(Color.WHITE)
            textSize = 14f
            isAllCaps = false
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#388E3C"))
                cornerRadius = dpToPx(12).toFloat()
            }
            background = bg
            setPadding(dpToPx(16), dpToPx(14), dpToPx(16), dpToPx(14))
            setOnClickListener {
                // Abre o Akilli
                val akillIntent = Intent(this@BlockOverlayActivity, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra("show_motivation", true)
                }
                startActivity(akillIntent)
                finish()
            }
        }
        val btnTarefaParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, 0, 0, dpToPx(12))
        }
        mainLayout.addView(btnTarefa, btnTarefaParams)

        // Botão "Me lembre em 2 minutos" (secundário - laranja)
        val btnSnooze = Button(this).apply {
            text = "⏰ Me lembre novamente em 2 minutos"
            setTextColor(Color.WHITE)
            textSize = 14f
            isAllCaps = false
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#F57C00"))
                cornerRadius = dpToPx(12).toFloat()
            }
            background = bg
            setPadding(dpToPx(16), dpToPx(14), dpToPx(16), dpToPx(14))
            setOnClickListener {
                // Pausa o bloqueio por 2 minutos enviando pro AppBlockerService
                AppBlockerForegroundService.startSnooze(blockedPackage)
                finish()
            }
        }
        val btnSnoozeParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
        mainLayout.addView(btnSnooze, btnSnoozeParams)

        setContentView(rootLayout, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    override fun onBackPressed() {
        // Impede voltar com botão back — força a decisão
        // Abre o Akilli ao invés de voltar ao app bloqueado
        val akillIntent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(akillIntent)
        finish()
    }
}
