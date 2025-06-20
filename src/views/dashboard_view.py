import flet as ft
from datetime import datetime

def build_dashboard_view(controller) -> ft.ListView:
    state = controller.app_state
    has_data = any(state.calculated_indices.values())

    dashboard_list = ft.ListView(expand=True, spacing=12, padding=10)

    welcome_header = ft.Container(
        content=ft.Column([
            ft.Image(src="icontest.ico", width=64, height=64),
            ft.Text("Bem-vindo ao BoviCheck!", size=24, weight=ft.FontWeight.BOLD),
            ft.Text("Seu painel para análise de índices zootécnicos.", size=15),
            ft.Divider(height=20, thickness=1),
        ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=5),
        padding=ft.padding.only(top=15, bottom=10)
    )
    dashboard_list.controls.append(welcome_header)
    
    quick_actions_title = ft.Text("Ações Rápidas", size=18, weight=ft.FontWeight.BOLD)
    quick_actions = ft.Card(ft.Container(ft.Column([
        ft.ListTile(leading=ft.Icon(ft.Icons.ADD_CHART), title=ft.Text("Calcular Novo Índice"), on_click=lambda _: controller.page.go("/indices")),
        ft.ListTile(leading=ft.Icon(ft.Icons.CHAT_BUBBLE_OUTLINE), title=ft.Text("Histórico do Chat"), on_click=lambda _: controller.page.go("/ai/history"), disabled=not state.ai_settings.get("enabled")),
        ft.ListTile(leading=ft.Icon(ft.Icons.SETTINGS), title=ft.Text("Configurações"), on_click=lambda _: controller.page.go("/settings/general")),
    ]), padding=ft.padding.symmetric(vertical=10)))
    
    dashboard_list.controls.extend([quick_actions_title, quick_actions])
    
    if state.ai_settings.get("enabled") and state.ai_settings.get("suggestions_on_dashboard"):
        suggestion_text = ft.Markdown(
            "Clique no botão para receber uma análise geral dos seus índices.", 
            selectable=True,
            extension_set=ft.MarkdownExtensionSet.GITHUB_WEB,
            opacity=0.7
        )
        loading_indicator = ft.ProgressRing(visible=False, width=16, height=16)
        
        continue_chat_button = ft.ElevatedButton(
            "Conversar sobre isso",
            icon=ft.Icons.CHAT_BUBBLE_OUTLINE,
            visible=False,
            on_click=controller.handle_continue_in_chat_click
        )

        generate_button = ft.FilledButton(
            "Gerar Sugestão", 
            icon=ft.Icons.AUTO_AWESOME,
            on_click=lambda e: controller.handle_dashboard_suggestion_click(e, suggestion_text, loading_indicator, continue_chat_button)
        )

        ai_card = ft.Card(
            ft.Container(
                ft.Column([
                    ft.ListTile(leading=ft.Icon(ft.Icons.INSIGHTS_ROUNDED, color=ft.Colors.PRIMARY), title=ft.Text("Análise com IA", weight=ft.FontWeight.BOLD)),
                    ft.Container(content=suggestion_text, padding=ft.padding.symmetric(horizontal=16, vertical=5)),
                    ft.Container(
                        content=ft.Row([loading_indicator, continue_chat_button, generate_button], alignment=ft.MainAxisAlignment.END, spacing=10),
                        padding=ft.padding.only(right=8, bottom=8)
                    )
                ]),
                padding=ft.padding.only(top=5)
            ),
            elevation=1.5
        )
        dashboard_list.controls.append(ai_card)

    if not has_data:
        empty_msg = ft.Container(ft.Column([
                ft.Icon(ft.Icons.INBOX_OUTLINED, size=50, opacity=0.5),
                ft.Text("Dashboard Vazio", size=18, weight=ft.FontWeight.BOLD),
                ft.Text("Nenhum índice foi calculado ainda.", text_align=ft.TextAlign.CENTER),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10),
            padding=40, alignment=ft.alignment.center
        )
        dashboard_list.controls.append(empty_msg)
    else:
        summary_title = ft.Container(
            content=ft.Text("Resumo dos Índices", size=18, weight=ft.FontWeight.BOLD),
            margin=ft.margin.only(top=15)
        )
        dashboard_list.controls.append(summary_title)
        
        sorted_indices = sorted(state.calculated_indices.items())
        for name, results in sorted_indices:
            if not results: continue
            try:
                latest = sorted(results, key=lambda x: datetime.strptime(f"{x['Data']} {x['Hora']}", "%d/%m/%Y %H:%M"), reverse=True)[0]
            except (ValueError, KeyError):
                latest = results[-1]
            
            latest_result_text = latest.get('Resultado', 'N/A')
            parts = latest_result_text.split(' ', 1)
            value = parts[0]
            unit = parts[1] if len(parts) > 1 else ""

            card_header = ft.Row(
                [
                    _get_index_icon(name, unit),
                    ft.Text(name, weight=ft.FontWeight.BOLD, size=16, expand=True),
                    ft.IconButton(
                        icon=ft.Icons.DELETE_SWEEP_OUTLINED, icon_color="error", tooltip="Excluir todos os valores deste índice",
                        on_click=lambda _, n=name: controller.page.go(f"/index/{controller.to_safe_route(n)}/delete_all_confirm")
                    ),
                ],
                vertical_alignment=ft.CrossAxisAlignment.CENTER
            )

            card_body = ft.Row(
                [
                    ft.Text(value, size=32, weight=ft.FontWeight.BOLD, color="primary"),
                    ft.Container(width=2),
                    ft.Text(unit, size=14, color="onSurfaceVariant", weight=ft.FontWeight.W_300, offset=ft.Offset(0, 0.35)),
                ],
                alignment=ft.MainAxisAlignment.CENTER
            )

            card_footer = ft.Text(
                f"Última medição em: {latest.get('Data', 'N/A')} às {latest.get('Hora', 'N/A')}",
                size=11, color="onSurfaceVariant", text_align=ft.TextAlign.CENTER
            )

            card = ft.Card(
                content=ft.Container(
                    content=ft.Column(
                        [
                            card_header,
                            ft.Divider(height=10),
                            card_body,
                            card_footer
                        ],
                        spacing=5,
                    ),
                    on_click=lambda _, n=name: controller.page.go(f"/index/{controller.to_safe_route(n)}/history"),
                    ink=True,
                    padding=12,
                ),
                elevation=2
            )
            dashboard_list.controls.append(card)
            
    return dashboard_list

def _get_index_icon(index_name: str, result_value: str) -> ft.Icon:
    if "Taxa" in index_name or "%" in result_value: icon_name = ft.Icons.PERCENT_OUTLINED
    elif "Peso" in index_name or "kg" in result_value: icon_name = ft.Icons.SCALE_OUTLINED
    elif "GMD" in index_name: icon_name = ft.Icons.SPEED_OUTLINED
    elif "Idade" in index_name or "Intervalo" in index_name: icon_name = ft.Icons.CALENDAR_MONTH_OUTLINED
    elif "Lotação" in index_name: icon_name = ft.Icons.GROUP_WORK_OUTLINED
    elif "Leite" in index_name: icon_name = ft.Icons.WATER_DROP_OUTLINED
    else: icon_name = ft.Icons.TRENDING_UP
    return ft.Icon(name=icon_name, size=24)