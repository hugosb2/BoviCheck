import flet as ft
from datetime import datetime

def build_ai_history_view(controller) -> ft.Container:
    ai_enabled = controller.app_state.ai_settings.get("enabled", False)
    if not ai_enabled:
        return ft.Container(
            content=ft.Column(
                [
                    ft.Icon(ft.Icons.VOICE_OVER_OFF, size=60, opacity=0.3),
                    ft.Text("Funcionalidade de IA desabilitada", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Você pode ativar a IA em 'Configurações' -> 'Configurações de IA'."),
                    ft.ElevatedButton(
                        "Ir para Configurações", 
                        icon=ft.Icons.SETTINGS,
                        on_click=lambda _: controller.page.go("/ai/settings")
                    )
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=15,
                expand=True,
                alignment=ft.MainAxisAlignment.CENTER
            ),
            padding=20
        )
    
    chat_history = sorted(
        controller.app_state.chat_history,
        key=lambda chat: datetime.fromisoformat(chat['timestamp']),
        reverse=True
    )

    history_list_view = ft.ListView(expand=True, spacing=10, padding=10)

    if not chat_history:
        history_list_view.controls.append(
            ft.Column(
                [
                    ft.Icon(ft.Icons.CHAT_BUBBLE_OUTLINE_ROUNDED, size=60, opacity=0.3),
                    ft.Text("Nenhuma conversa encontrada.", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Clique em 'Nova Conversa' para começar.", text_align=ft.TextAlign.CENTER),
                ],
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=10,
                expand=True,
                alignment=ft.MainAxisAlignment.CENTER
            )
        )
    else:
        for chat in chat_history:
            chat_id = chat['id']
            
            text_content = ft.Column(
                [
                    ft.Text(chat['title'], weight=ft.FontWeight.BOLD, max_lines=1, overflow=ft.TextOverflow.ELLIPSIS),
                    ft.Text(f"Criado em: {datetime.fromisoformat(chat['timestamp']).strftime('%d/%m/%Y %H:%M')}", size=12, opacity=0.7),
                ],
                spacing=2,
                alignment=ft.MainAxisAlignment.CENTER,
            )

            action_buttons = ft.Row([
                ft.IconButton(
                    icon=ft.Icons.EDIT_OUTLINED,
                    tooltip="Renomear conversa",
                    data=chat_id,
                    on_click=controller.open_rename_dialog,
                ),
                ft.IconButton(
                    icon=ft.Icons.DELETE_OUTLINE,
                    icon_color=ft.Colors.with_opacity(0.7, ft.Colors.ERROR),
                    tooltip="Apagar conversa",
                    on_click=lambda _, cid=chat_id: controller.page.go(f"/ai/chat/delete/{cid}/confirm"),
                ),
            ])

            card = ft.Card(
                content=ft.Row(
                    [
                        ft.Container(
                            content=text_content,
                            on_click=lambda _, cid=chat_id: controller.open_chat(cid),
                            expand=True,
                            padding=ft.padding.only(left=15, top=10, bottom=10)
                        ),
                        action_buttons,
                    ],
                    vertical_alignment=ft.CrossAxisAlignment.CENTER,
                ),
                elevation=1.5
            )
            history_list_view.controls.append(card)

    return ft.Container(
        content=ft.Column(
            [
                ft.Row(
                    [
                        ft.Text("Histórico de Conversas", size=22, weight=ft.FontWeight.BOLD, expand=True),
                        ft.FilledButton(
                            "Nova Conversa",
                            icon=ft.Icons.ADD_COMMENT_OUTLINED,
                            on_click=lambda _: controller.start_new_chat()
                        )
                    ],
                    alignment=ft.MainAxisAlignment.SPACE_BETWEEN
                ),
                ft.Divider(),
                history_list_view
            ]
        ),
        padding=15,
        expand=True
    )