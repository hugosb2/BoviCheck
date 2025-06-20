import flet as ft

def create_confirm_delete_all_data_view(controller) -> ft.Container:
    delete_button_style = ft.ButtonStyle(
        bgcolor="error",
        color="onError"
    )
    content_column = ft.Column(
        [
            ft.Icon(name=ft.Icons.DELETE_FOREVER_OUTLINED, color="error", size=50),
            ft.Text("Apagar Todos os Dados?", size=20, weight=ft.FontWeight.BOLD),
            ft.Text("Esta ação é IRREVERSÍVEL e excluirá todos os seus índices salvos e histórico de conversas.", text_align=ft.TextAlign.CENTER),
            ft.Row(
                [
                    ft.TextButton("Cancelar", on_click=controller.go_back),
                    ft.FilledButton(
                        "Sim, Apagar Tudo",
                        on_click=controller.handle_delete_all_data_confirmed,
                        style=delete_button_style
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER
            )
        ],
        spacing=15, horizontal_alignment=ft.CrossAxisAlignment.CENTER,
    )
    return ft.Container(
        content=ft.Card(ft.Container(content_column, padding=25)),
        alignment=ft.alignment.center, expand=True
    )

def create_confirm_delete_index_calc_view(controller, index_name: str) -> ft.Container:
    delete_button_style = ft.ButtonStyle(bgcolor="error", color="onError")
    content_column = ft.Column(
        [
            ft.Icon(name=ft.Icons.WARNING_AMBER_ROUNDED, color=ft.Colors.AMBER_700, size=40),
            ft.Text(f"Excluir todo o histórico para:", size=16, text_align=ft.TextAlign.CENTER),
            ft.Text(f"'{index_name}'?", size=18, weight=ft.FontWeight.BOLD, text_align=ft.TextAlign.CENTER),
            ft.Text("Esta ação não pode ser desfeita.", text_align=ft.TextAlign.CENTER),
            ft.Row([
                    ft.TextButton("Cancelar", on_click=controller.go_back),
                    ft.FilledButton("Excluir Histórico", on_click=lambda e: controller.handle_delete_index_confirmed(index_name), style=delete_button_style),
                ], alignment=ft.MainAxisAlignment.CENTER
            )
        ],
        spacing=15, horizontal_alignment=ft.CrossAxisAlignment.CENTER,
    )
    return ft.Container(content=ft.Card(ft.Container(content_column, padding=25)), alignment=ft.alignment.center, expand=True)


def create_confirm_delete_single_calc_view(controller, index_name: str, calc_id: str) -> ft.Container:
    delete_button_style = ft.ButtonStyle(bgcolor="error", color="onError")
    calc, _ = controller.app_state.get_calculation_by_id(index_name, calc_id)
    if not calc:
        return ft.Container(content=ft.Text("Erro: Cálculo não encontrado."))
    
    calc_repr = f"{calc.get('Resultado', 'N/A')} em {calc.get('Data', 'N/A')}"
    content_column = ft.Column(
        [
            ft.Icon(name=ft.Icons.DELETE_OUTLINE_ROUNDED, color="error", size=40),
            ft.Text("Excluir esta medição?", size=18, weight=ft.FontWeight.BOLD),
            ft.Text(calc_repr, text_align=ft.TextAlign.CENTER),
            ft.Row(
                [
                    ft.TextButton("Cancelar", on_click=controller.go_back),
                    ft.FilledButton(
                        "Excluir",
                        on_click=lambda e: controller.handle_delete_single_calc_confirmed(index_name, calc_id),
                        style=delete_button_style
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER
            )
        ],
        spacing=15, horizontal_alignment=ft.CrossAxisAlignment.CENTER
    )
    return ft.Container(
        content=ft.Card(ft.Container(content_column, padding=25)),
        alignment=ft.alignment.center, expand=True
    )

def create_confirm_delete_chat_view(controller, chat_id: str) -> ft.Container:
    delete_button_style = ft.ButtonStyle(bgcolor="error", color="onError")
    chat = controller.app_state.get_chat_by_id(chat_id)
    if not chat:
        return ft.Container(content=ft.Text("Erro: Conversa não encontrada."))

    content_column = ft.Column(
        [
            ft.Icon(name=ft.Icons.DELETE_SWEEP_OUTLINED, color="error", size=40),
            ft.Text("Excluir esta conversa?", size=18, weight=ft.FontWeight.BOLD),
            ft.Text(f"'{chat.get('title')}'", text_align=ft.TextAlign.CENTER, italic=True),
            ft.Text("Esta ação não pode ser desfeita.", text_align=ft.TextAlign.CENTER, size=12),
            ft.Row(
                [
                    ft.TextButton("Cancelar", on_click=controller.go_back),
                    ft.FilledButton(
                        "Excluir",
                        on_click=lambda e: controller.handle_delete_chat_confirmed(chat_id),
                        style=delete_button_style
                    ),
                ],
                alignment=ft.MainAxisAlignment.CENTER
            )
        ],
        spacing=15, horizontal_alignment=ft.CrossAxisAlignment.CENTER
    )
    return ft.Container(
        content=ft.Card(ft.Container(content_column, padding=25)),
        alignment=ft.alignment.center, expand=True
    )