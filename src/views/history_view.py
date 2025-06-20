import flet as ft
from datetime import datetime
import re

def build_index_history_view(controller, index_name: str) -> ft.Container:
    all_calculations = controller.app_state.calculated_indices.get(index_name, [])

    controller.history_start_date_input = ft.TextField(
        label="Data Inicial",
        hint_text="DD/MM/AAAA",
        border_color="outline",
        cursor_color="primary",
        on_change=controller.handle_date_input_change,
        keyboard_type=ft.KeyboardType.NUMBER,
        max_length=10
    )
    controller.history_end_date_input = ft.TextField(
        label="Data Final",
        hint_text="DD/MM/AAAA",
        border_color="outline",
        cursor_color="primary",
        on_change=controller.handle_date_input_change,
        keyboard_type=ft.KeyboardType.NUMBER,
        max_length=10
    )

    filter_tile = ft.ExpansionTile(
        title=ft.Text("Filtrar por Período", weight=ft.FontWeight.BOLD),
        leading=ft.Icon(ft.Icons.FILTER_LIST_ROUNDED),
        affinity=ft.TileAffinity.PLATFORM,
        initially_expanded=False,
        controls=[
            ft.Container(
                content=ft.Column([
                    controller.history_start_date_input,
                    controller.history_end_date_input,
                    ft.Row(
                        controls=[
                            ft.TextButton(
                                "Limpar",
                                icon=ft.Icons.CLEAR,
                                on_click=lambda e: controller.handle_clear_date_filter(e, index_name)
                            ),
                            ft.FilledButton(
                                "Filtrar",
                                icon=ft.Icons.FILTER_ALT,
                                on_click=lambda e: controller.handle_apply_date_filter(e, index_name),
                                expand=True
                            ),
                        ],
                        alignment=ft.MainAxisAlignment.END
                    )
                ]),
                padding=ft.padding.only(left=25, right=15, bottom=10, top=5)
            )
        ]
    )

    if not all_calculations:
        return ft.Container(
            content=ft.Column(
                [ft.Text(f"Nenhum valor encontrado para '{index_name}'.", weight=ft.FontWeight.BOLD)],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=10
            ),
            expand=True,
            alignment=ft.alignment.center
        )

    try:
        sorted_calcs = sorted(
            all_calculations,
            key=lambda x: datetime.strptime(f"{x.get('Data','')} {x.get('Hora','')}", "%d/%m/%Y %H:%M"),
            reverse=True
        )
    except (ValueError, KeyError):
        sorted_calcs = all_calculations

    controller.history_details_container = ft.Container(
        content=ft.Text("Clique em uma barra para ver detalhes.", italic=True, text_align=ft.TextAlign.CENTER),
        padding=10,
    )
    
    chart = _build_bar_chart(controller, sorted_calcs, index_name)
    
    chart_container = ft.Container(
        content=chart,
        padding=10,
        border=ft.border.all(1, ft.Colors.with_opacity(0.2, ft.Colors.OUTLINE)),
        border_radius=8
    )
    controller.history_chart_container = chart_container

    column_content = ft.Column(
        [
            filter_tile,
            ft.Divider(height=10),
            chart_container,
            ft.Divider(height=15),
            ft.Text("Detalhes da Medição", size=16, weight=ft.FontWeight.W_600),
            controller.history_details_container,
            ft.Divider(height=15),
        ],
        scroll=ft.ScrollMode.ADAPTIVE,
        expand=True,
        spacing=10
    )

    state = controller.app_state
    if state.ai_settings.get("enabled") and state.ai_settings.get("suggestions_on_dashboard"):
        suggestion_text = ft.Markdown(
            f"Clique para obter uma sugestão sobre {index_name}.",
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
            data=index_name,
            on_click=lambda e: controller.handle_index_suggestion_click(e, suggestion_text, loading_indicator, continue_chat_button)
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
        column_content.controls.append(ai_card)

    return ft.Container(
        content=column_content,
        padding=10,
        expand=True
    )

def _build_bar_chart(controller, calcs: list, index_name: str) -> ft.Row:
    if not calcs:
        return ft.Row(
            controls=[
                ft.Container(
                    content=ft.Text("Nenhum dado encontrado para o período selecionado.", italic=True),
                    padding=20,
                    alignment=ft.alignment.center
                )
            ],
            alignment=ft.MainAxisAlignment.CENTER
        )

    bar_items, parsed_calcs, max_val = [], [], 0
    for calc in calcs:
        try:
            val_str = calc.get("Resultado", "0 ").split()[0].replace(',', '.')
            numeric_val = float(val_str)
            parsed_calcs.append({"value": numeric_val, "data": calc})
            if numeric_val > max_val: max_val = numeric_val
        except (ValueError, IndexError):
            parsed_calcs.append({"value": 0, "data": calc})
    
    for item in parsed_calcs:
        calc_data = item["data"]
        bar_height = max(15, (item["value"] / max_val * 100)) if max_val > 0 else 15
        bar = ft.Container(
            width=55, height=bar_height,
            bgcolor=ft.Colors.PRIMARY,
            border_radius=ft.border_radius.only(top_left=5, top_right=5),
            tooltip=f"{calc_data.get('Resultado', '')}\nEm: {calc_data.get('Data', '')}",
            on_click=lambda _, d=calc_data: controller.handle_history_item_selected(d, index_name),
            ink=True
        )
        date_str = datetime.strptime(calc_data.get('Data'), "%d/%m/%Y").strftime("%d/%m")
        bar_col = ft.Column(
            [ft.Text(f"{item['value']:.2f}", size=11, weight=ft.FontWeight.BOLD), bar, ft.Text(date_str, size=9)],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=3
        )
        bar_items.append(bar_col)
    
    return ft.Row(controls=bar_items, scroll=ft.ScrollMode.ADAPTIVE, vertical_alignment=ft.CrossAxisAlignment.END)

def build_details_card(controller, calc_data, index_name) -> ft.Card:
    safe_name = controller.to_safe_route(index_name)
    
    delete_button_style = ft.ButtonStyle(
        bgcolor="error",
        color="onError"
    )
    
    return ft.Card(
        content=ft.Container(
            content=ft.Column([
                ft.Text(f"Resultado: {calc_data.get('Resultado', 'N/A')}", weight=ft.FontWeight.BOLD),
                ft.Text(f"Data: {calc_data.get('Data', 'N/A')} às {calc_data.get('Hora', 'N/A')}", size=13),
                ft.Row([
                    ft.ElevatedButton("Editar", icon=ft.Icons.EDIT_OUTLINED, on_click=lambda _: controller.page.go(f"/index/{safe_name}/edit/{calc_data['id']}")),
                    ft.FilledButton("Excluir", icon=ft.Icons.DELETE_OUTLINE, style=delete_button_style, on_click=lambda _: controller.page.go(f"/index/{safe_name}/delete_single/{calc_data['id']}/confirm"))
                ], alignment=ft.MainAxisAlignment.END)
            ]),
            padding=12
        ),
        elevation=1.5
    )