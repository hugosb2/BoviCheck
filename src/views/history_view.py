import flet as ft
from datetime import datetime

def build_index_history_view(controller, index_name: str) -> ft.Container:
    calculations = controller.app_state.calculated_indices.get(index_name, [])

    if not calculations:
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
            calculations,
            key=lambda x: datetime.strptime(f"{x.get('Data','')} {x.get('Hora','')}", "%d/%m/%Y %H:%M"),
            reverse=True
        )
    except (ValueError, KeyError):
        sorted_calcs = calculations

    controller.history_details_container = ft.Container(
        content=ft.Text("Clique em uma barra para ver detalhes.", italic=True, text_align=ft.TextAlign.CENTER),
        padding=10,
    )
    
    chart = _build_bar_chart(controller, sorted_calcs, index_name)

    column_content = ft.Column(
        [
            ft.Text(f"Histórico: {index_name}", size=20, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER),
            ft.Divider(height=10),
            ft.Container(
                content=chart,
                padding=10,
                border=ft.border.all(1, ft.Colors.with_opacity(0.2, ft.Colors.OUTLINE)),
                border_radius=8
            ),
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
    bar_items, parsed_calcs, max_val = [], [], 0
    for calc in calcs:
        try:
            val_str = calc.get("Resultado", "0 ").split()[0].replace(',', '.')
            numeric_val = float(val_str)
            parsed_calcs.append({"value": numeric_val, "data": calc})
            if numeric_val > max_val: max_val = numeric_val
        except (ValueError, IndexError):
            parsed_calcs.append({"value": 0, "data": calc})
    
    if not parsed_calcs:
        return ft.Row([ft.Text("Nenhum dado para exibir no gráfico.")])

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
                    ft.FilledButton("Excluir", icon=ft.Icons.DELETE_OUTLINED, style=delete_button_style, on_click=lambda _: controller.page.go(f"/index/{safe_name}/delete_single/{calc_data['id']}/confirm"))
                ], alignment=ft.MainAxisAlignment.END)
            ]),
            padding=12
        ),
        elevation=1.5
    )